/*
 * Implementation of the class PyObjCClass_Type, that is the class representing
 * Objective-C classes.
 *
 */
#include "pyobjc.h"

#include <stddef.h>

NS_ASSUME_NONNULL_BEGIN

int
PyObjCClass_SetHidden(PyObject* tp, SEL sel, BOOL classMethod, PyObject* metadata)
{
    PyObject* hidden;
    PyObject* v;
    int       r;

    if (classMethod) {
        hidden = ((PyObjCClassObject*)tp)->hiddenClassSelectors;
        if (hidden == NULL) {
            hidden = PyDict_New();

            if (hidden == NULL) {
                return -1;
            }

            ((PyObjCClassObject*)tp)->hiddenClassSelectors = hidden;
        }

    } else {
        hidden = ((PyObjCClassObject*)tp)->hiddenSelectors;

        if (hidden == NULL) {
            hidden = PyDict_New();

            if (hidden == NULL) {
                return -1;
            }

            ((PyObjCClassObject*)tp)->hiddenSelectors = hidden;
        }
    }

    v = PyObjCBytes_InternFromString(sel_getName(sel));
    if (v == NULL) {
        return -1;
    }
    r = PyDict_SetItem(hidden, v, metadata);
    Py_DECREF(v);
    return r;
}

PyObject* _Nullable PyObjCClass_HiddenSelector(PyObject* tp, SEL sel, BOOL classMethod)
{
    PyObject*  mro;
    Py_ssize_t i, n;
    if (tp == NULL) {
        return NULL;
    }

    mro = ((PyTypeObject*)tp)->tp_mro;
    if (mro == NULL) {
        return NULL;
    }

    PyObjC_Assert(PyTuple_Check(mro), NULL);
    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        PyObject* base = PyTuple_GET_ITEM(mro, i);
        if (PyObjCClass_Check(base)) {
            PyObject* hidden;

            if (classMethod) {
                hidden = ((PyObjCClassObject*)base)->hiddenClassSelectors;

            } else {
                hidden = ((PyObjCClassObject*)base)->hiddenSelectors;
            }

            if (hidden != NULL) {
                PyObject* v = PyObjCBytes_InternFromString(sel_getName(sel));

                if (v == NULL) {
                    PyErr_Clear();

                } else {
                    /* XXX: Should change to PyDict_GetItemWithError */
                    PyObject* r = PyDict_GetItem(hidden, v);
                    Py_DECREF(v);
                    if (r == NULL) {
                        PyErr_Clear();

                    } else {
                        return r;
                    }
                }
            }
        }
    }

    return NULL;
}

/*
 * Support for NSData/NSMutableData to have buffer API
 *
 */

static int
nsdata_getbuffer(PyObject* obj, Py_buffer* view, int flags)
{
    NSData* self = (NSData*)PyObjCObject_GetObject(obj);
    int r = PyBuffer_FillInfo(view, obj, (void*)[self bytes], [self length], 1, flags);
    return r;
}

static int
nsmutabledata_getbuffer(PyObject* obj, Py_buffer* view, int flags)
{
    NSMutableData* self = (NSMutableData*)PyObjCObject_GetObject(obj);
    int            r;
    if ((flags & PyBUF_WRITABLE) == PyBUF_WRITABLE) {
        r = PyBuffer_FillInfo(view, obj, (void*)[self mutableBytes], [self length], 0,
                              flags);

    } else {
        r = PyBuffer_FillInfo(view, obj, (void*)[self bytes], [self length], 1, flags);
    }
    return r;
}

static PyBufferProcs nsdata_as_buffer = {
    .bf_getbuffer = nsdata_getbuffer,
};

static PyBufferProcs nsmutabledata_as_buffer = {
    .bf_getbuffer = nsmutabledata_getbuffer,
};

PyDoc_STRVAR(class_doc,
             "objc_class(name, bases, dict) -> a new Objective-C class\n" CLINIC_SEP "\n"
             "objc_class is the meta-type for Objective-C classes. It should not be\n"
             "necessary to manually create instances of this type, those are \n"
             "created by subclassing and existing Objective-C class.\n"
             "\n"
             "The list of bases must start with an existing Objective-C class, and \n"
             "cannot contain other Objective-C classes. The list may contain\n"
             "informal_interface objects, those are used during the calculation of\n"
             "method signatures and will not be visible in the list of base-classes\n"
             "of the created class.");

static int update_convenience_methods(PyObject* cls);

/*
 *
 *  Class Registry
 *
 */

/*!
 * @const class_registry
 * @discussion
 *    This structure is used to keep references to all class objects created
 *    by this module. This is necessary to be able to avoid creating two
 *    wrappers for an Objective-C class.
 *
 *    The key is the Objective-C class, the value is its wrapper.
 */
static NSMapTable* _Nullable class_registry     = NULL;
static NSMapTable* _Nullable metaclass_to_class = NULL;

/*!
 * @function objc_class_register
 * @abstract Add a class to the class registry
 * @param objc_class An Objective-C class
 * @param py_class   The python wrapper for the Objective-C class
 * @result Returns -1 on error, 0 on success
 */
static int
objc_class_register(Class objc_class, PyObject* py_class)
{
    if (class_registry == NULL) {
        class_registry = NSCreateMapTable(PyObjCUtil_PointerKeyCallBacks,
                                          PyObjCUtil_PointerValueCallBacks,
                                          PYOBJC_EXPECTED_CLASS_COUNT);
        if (class_registry == NULL) {
            PyErr_SetString(PyObjCExc_InternalError, "Cannot create class registry");
            return -1;
        }
    }

    if (NSMapGet(class_registry, objc_class)) {
        PyErr_Format(PyObjCExc_InternalError, "Registering class '%.100s' more than once",
                     class_getName(objc_class));
        return -1;
    }

    Py_INCREF(py_class);
    NSMapInsert(class_registry, objc_class, py_class);

    return 0;
}

static int
objc_metaclass_register(PyTypeObject* meta_class, Class class)
{
    if (metaclass_to_class == NULL) {
        metaclass_to_class = NSCreateMapTable(PyObjCUtil_PointerKeyCallBacks,
                                              PyObjCUtil_PointerValueCallBacks,
                                              PYOBJC_EXPECTED_CLASS_COUNT);
        if (metaclass_to_class == NULL) {
            PyErr_SetString(PyObjCExc_InternalError, "Cannot create metaclass registry");
            return -1;
        }
    }

    if (NSMapGet(metaclass_to_class, meta_class)) {
        PyErr_SetString(PyObjCExc_InternalError, "Registering metaclass more than once");
        return -1;
    }

    Py_INCREF(meta_class);
    NSMapInsert(metaclass_to_class, meta_class, class);

    return 0;
}

static Class _Nullable objc_metaclass_locate(PyObject* meta_class)
{
    Class result;

    if (metaclass_to_class == NULL)
        return NULL;
    if (meta_class == NULL)
        return NULL;

    result = NSMapGet(metaclass_to_class, meta_class);
    return result;
}

/*!
 * @function objc_class_locate
 * @abstract Find the Python wrapper for an Objective-C class
 * @param objc_class An Objective-C class
 * @result Returns the Python wrapper for the class, or NULL
 * @discussion
 *     This function does not raise an Python exception when the
 *     wrapper cannot be found.
 *
 * XXX: Is this function needed? Why not use the same registry
 *      as used by objc-object?
 */
PyObject* _Nullable objc_class_locate(Class objc_class)
{
    PyObject* result;

    if (class_registry == NULL)
        return NULL;
    if (objc_class == NULL)
        return NULL;

    result = NSMapGet(class_registry, objc_class);
    Py_XINCREF(result);
    return result;
}

/* Create a new objective-C metaclass proxy
 *
 * Returns a new reference.
 */
static PyTypeObject* _Nullable PyObjCClass_NewMetaClass(Class objc_class)
{
    PyTypeObject* result;
    Class         objc_meta_class = object_getClass(objc_class);

    if (unlikely(class_isMetaClass(objc_class))) {
        objc_meta_class = objc_class;
    }

    if (objc_meta_class == nil) {
        Py_INCREF(&PyObjCClass_Type);
        return &PyObjCClass_Type;
    }

    /* Create a metaclass proxy for the metaclass of the given class */
    result = (PyTypeObject*)objc_class_locate(objc_meta_class);
    if (result != NULL) {
        return result;
    }

    Class super_class = nil;

    if (unlikely(class_isMetaClass(objc_class))) {
        super_class = class_getSuperclass(objc_meta_class);
        if (!class_isMetaClass(super_class)) {
            /* NSObject's metaclass inherits from NSObject, don't
             * model that in Python. */
            super_class = nil;
        }

    } else {
        super_class = class_getSuperclass(objc_class);
    }

    PyTypeObject* py_super_class;
    if (super_class == nil) {
        Py_INCREF(&PyObjCClass_Type);
        py_super_class = &PyObjCClass_Type;

    } else {
        py_super_class = PyObjCClass_NewMetaClass(super_class);
        if (py_super_class == NULL) {
            return NULL;
        }
    }

    /* We now know the superclass of our metaclass, build the actual
     * metaclass.
     */
    PyObject* dict  = PyDict_New();
    PyObject* bases = PyTuple_New(1);

    PyTuple_SET_ITEM(bases, 0, (PyObject*)py_super_class);

    PyObject* args = PyTuple_New(3);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(class_getName(objc_class)));
    PyTuple_SetItem(args, 1, bases);
    PyTuple_SetItem(args, 2, dict);

    result = (PyTypeObject*)PyType_Type.tp_new(&PyType_Type, args, NULL);
    Py_DECREF(args);
    if (result == NULL) {
        return NULL;
    }

    ((PyObjCClassObject*)result)->class = objc_meta_class;

    if (objc_class_register(objc_meta_class, (PyObject*)result) == -1) {
        Py_DECREF(result);
        return NULL;
    }

    if (objc_metaclass_register(result, objc_class) == -1) {
        /* Whoops, no such thing */
        /* XXX */
        // objc_class_unregister(objc_meta_class);
        return NULL;
    }

    return (PyTypeObject*)result;
}

/*
 * class_new: Create a new objective-C class, as a subclass of 'type'. This is
 * PyObjCClass_Type.tp_new.
 *
 * Note: This function creates new _classes_
 */

static int
class_init(PyObject* cls, PyObject* args, PyObject* kwds)
{
    if (kwds != NULL) {
        if (PyDict_Check(kwds) && PyDict_Size(kwds) == 1) {

            PyObject* v = PyDict_GetItemStringWithError(kwds, "protocols");
            if (v == NULL && PyErr_Occurred()) {
                return -1;
            }

            /* XXX: Not clear what this tries to accomplish */
            if (v != NULL) {
                return PyType_Type.tp_init(cls, args, NULL);
            }
        }
    }
    return PyType_Type.tp_init(cls, args, kwds);
}

static PyObject* _Nullable class_new(PyTypeObject* type __attribute__((__unused__)),
                                     PyObject* _Nullable args, PyObject* _Nullable kwds)
{
    static PyObject*   all_python_classes = NULL;
    static char*       keywords[] = {"name", "bases", "dict", "protocols", "final", NULL};
    char*              name;
    PyObject*          bases;
    PyObject*          dict;
    PyObject*          old_dict;
    PyObject*          res;
    PyObject*          k;
    PyObject*          metadict;
    PyObject*          v;
    Py_ssize_t         i;
    Py_ssize_t         len;
    Class              objc_class = NULL;
    Class              super_class; /* XXX    = NULL; */
    PyObject*          py_super_class = NULL;
    PyObjCClassObject* info;
    PyObject*          keys;
    PyObject*          protocols;
    PyObject*          real_bases;
    PyObject*          delmethod;
    PyObject*          useKVOObj;
    Ivar               var;
    PyObject*          hiddenSelectors      = NULL;
    PyObject*          hiddenClassSelectors = NULL;
    PyObject*          arg_protocols        = NULL;
    BOOL               isCFProxyClass       = NO;
    int                r;
    int                final = 0;

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "sOO|Op", keywords, &name, &bases, &dict,
                                     &arg_protocols, &final)) {
        return NULL;
    }

    if (!PyTuple_Check(bases)) {
        PyErr_SetString(PyExc_TypeError, "'bases' must be tuple");
        return NULL;
    }

    len = PyTuple_Size(bases);
    if (len < 1) {
        PyErr_SetString(PyExc_TypeError, "'bases' must not be empty");
        return NULL;
    }

    py_super_class = PyTuple_GET_ITEM(bases, 0);
    if (py_super_class == NULL) {
        return NULL;
    }

    if (py_super_class == PyObjC_NSCFTypeClass) {
        /* A new subclass of NSCFType
         * -> a new proxy type for CoreFoundation classes
         */
        isCFProxyClass = YES;
    }

    if (!PyObjCClass_Check(py_super_class)) {
        PyErr_SetString(PyExc_TypeError, "first base class must "
                                         "be objective-C based");
        return NULL;
    }
    if (py_super_class == (PyObject*)&PyObjCObject_Type) {
        PyErr_SetString(PyExc_TypeError, "Cannot directly inherit from objc.objc_object");
        return NULL;
    }

    if (PyObjCClass_IsFinal((PyTypeObject*)py_super_class)) {
        PyErr_Format(PyExc_TypeError, "super class %s is final",
                     ((PyTypeObject*)py_super_class)->tp_name);
        return NULL;
    }

    super_class = PyObjCClass_GetClass(py_super_class);
    if (super_class == Nil) {
        /* This will always set an exception, only the root has
         * a Nil class and that's excluded above.
         */
        PyObjC_Assert(PyErr_Occurred(), NULL);
        return NULL;
    }
    if (PyObjCClass_CheckMethodList(py_super_class, 1) < 0) {
        return NULL;
    }

    hiddenSelectors = PyDict_New();
    if (hiddenSelectors == NULL) {
        return NULL;
    }

    hiddenClassSelectors = PyDict_New();
    if (hiddenClassSelectors == NULL) {
        Py_DECREF(hiddenSelectors);
        return NULL;
    }

    /*
     * __pyobjc_protocols__ contains the list of protocols supported
     * by an existing class.
     */
    protocols = PyObject_GetAttrString(py_super_class, "__pyobjc_protocols__");
    if (protocols == NULL) {
        PyErr_Clear();
        protocols = PyList_New(0);
        if (protocols == NULL) {
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

    } else {
        PyObject*  seq;
        Py_ssize_t protocols_len;

        seq = PySequence_Fast(protocols, "__pyobjc_protocols__ not a sequence?");
        if (seq == NULL) {
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            Py_DECREF(protocols);
            return NULL;
        }

        Py_DECREF(protocols);

        protocols_len = PySequence_Fast_GET_SIZE(seq);
        protocols     = PyList_New(protocols_len);
        if (protocols == NULL) {
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        for (i = 0; i < protocols_len; i++) {
            PyList_SET_ITEM(protocols, i, PySequence_Fast_GET_ITEM(seq, i));
            Py_INCREF(PySequence_Fast_GET_ITEM(seq, i));
        }

        Py_DECREF(seq);
    }

    real_bases = PyList_New(0);
    if (real_bases == NULL) {
        Py_DECREF(protocols);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        return NULL;
    }

    PyList_Append(real_bases, py_super_class);
    if (PyErr_Occurred()) {
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        Py_DECREF(protocols);
        Py_DECREF(real_bases);
        return NULL;
    }

    for (i = 1; i < len; i++) {
        v = PyTuple_GET_ITEM(bases, i);
        if (v == NULL) {
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        if (PyObjCClass_Check(v)) {
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            PyErr_SetString(PyExc_TypeError, "multiple objective-C bases");
            return NULL;

        } else if (PyObjCInformalProtocol_Check(v)) {
            r = PyList_Append(protocols, v);
            if (r == -1) {
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
            }

        } else if (PyObjCFormalProtocol_Check(v)) {
            r = PyList_Append(protocols, v);
            if (r == -1) {
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
            }

        } else {
            r = PyList_Append(real_bases, v);

            if (r == -1) {
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
            }
        }
    }

    if (arg_protocols != NULL) {
        PyObject*  seq;
        Py_ssize_t i, seqlen;

        seq = PySequence_Fast(arg_protocols, "'protocols' not a sequence?");
        if (seq == NULL) {
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        seqlen = PySequence_Fast_GET_SIZE(seq);
        for (i = 0; i < seqlen; i++) {
            if (PyObjCInformalProtocol_Check(PySequence_Fast_GET_ITEM(seq, i))
                || PyObjCFormalProtocol_Check(PySequence_Fast_GET_ITEM(seq, i))) {
                r = PyList_Append(protocols, PySequence_Fast_GET_ITEM(seq, i));
                if (r == -1) {
                    Py_DECREF(seq);
                    Py_DECREF(protocols);
                    Py_DECREF(real_bases);
                    Py_DECREF(hiddenSelectors);
                    Py_DECREF(hiddenClassSelectors);
                    return NULL;
                }

            } else {
                PyErr_Format(PyExc_TypeError,
                             "protocols list contains object that isn't an Objective-C "
                             "protocol, but type %s",
                             Py_TYPE(PySequence_Fast_GET_ITEM(seq, i))->tp_name);
                Py_DECREF(seq);
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                return NULL;
            }
        }
        Py_DECREF(seq);
    }

    /* Also look for '__pyobjc_protocols__' in the class dictionary,
     * makes it possible to write code that works in Python 2 as well
     * as python 3.
     */
    arg_protocols = PyDict_GetItemString(dict, "__pyobjc_protocols__");
    if (arg_protocols != NULL) {
        PyObject*  seq;
        Py_ssize_t i, seqlen;

        seq = PySequence_Fast(arg_protocols, "'__pyobjc_protocols__' not a sequence?");
        if (seq == NULL) {
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        seqlen = PySequence_Fast_GET_SIZE(seq);
        for (i = 0; i < seqlen; i++) {
            if (PyObjCInformalProtocol_Check(PySequence_Fast_GET_ITEM(seq, i))
                || PyObjCFormalProtocol_Check(PySequence_Fast_GET_ITEM(seq, i))) {
                r = PyList_Append(protocols, PySequence_Fast_GET_ITEM(seq, i));
                if (r == -1) {
                    Py_DECREF(seq);
                    Py_DECREF(protocols);
                    Py_DECREF(real_bases);
                    Py_DECREF(hiddenSelectors);
                    Py_DECREF(hiddenClassSelectors);
                    return NULL;
                }

            } else {
                PyErr_Format(PyExc_TypeError,
                             "protocols list contains object that isn't an Objective-C "
                             "protocol, but type %s",
                             Py_TYPE(PySequence_Fast_GET_ITEM(seq, i))->tp_name);
                Py_DECREF(seq);
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                return NULL;
            }
        }
        Py_DECREF(seq);
    }

    metadict = PyDict_New();
    if (metadict == NULL) {
        Py_DECREF(protocols);
        Py_DECREF(real_bases);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        return NULL;
    }

    if (isCFProxyClass) {
        objc_class = nil;

    } else {
        /* First generate the objective-C class. This may change the
         * class dict.
         */
        objc_class = PyObjCClass_BuildClass(super_class, protocols, name, dict, metadict,
                                            hiddenSelectors, hiddenClassSelectors);
        if (objc_class == Nil) {
            Py_DECREF(protocols);
            Py_DECREF(metadict);
            Py_DECREF(real_bases);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        /* PyObjCClass_BuildClass may have changed the super_class */
        /* This is a subclass of an existing class, the superclass will never be Nil */
        super_class    = (Class _Nonnull)class_getSuperclass(objc_class);
        py_super_class = PyObjCClass_New(super_class);
        if (py_super_class == NULL) {
            (void)PyObjCClass_UnbuildClass(objc_class);
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;

        } else {
            if (PyObjCClass_CheckMethodList(py_super_class, 1) < 0) {
                (void)PyObjCClass_UnbuildClass(objc_class);
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(metadict);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                return NULL;
            }
        }

        Py_DECREF(PyList_GET_ITEM(real_bases, 0));
        PyList_SET_ITEM(real_bases, 0, py_super_class);
    }

    v = PyList_AsTuple(real_bases);
    if (v == NULL) {
        if (objc_class != nil) {
            (void)PyObjCClass_UnbuildClass(objc_class);
        }
        Py_DECREF(metadict);
        Py_DECREF(protocols);
        Py_DECREF(real_bases);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        return NULL;
    }
    Py_DECREF(real_bases);
    real_bases = v;

    /* Verify that the class conforms to all protocols it claims to
     * conform to.
     */
    len = PyList_Size(protocols);
    for (i = 0; i < len; i++) {
        PyObject* p = PyList_GetItem(protocols, i);

        if (p == NULL) {
            PyErr_Clear();
            continue;
        }

        if (PyObjCInformalProtocol_Check(p)) {
            if (!PyObjCInformalProtocol_CheckClass(p, name, py_super_class, dict)) {
                Py_DECREF(real_bases);
                Py_DECREF(protocols);
                Py_DECREF(metadict);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                (void)PyObjCClass_UnbuildClass(objc_class);
                return NULL;
            }

        } else if (PyObjCFormalProtocol_Check(p)) {
            if (!PyObjCFormalProtocol_CheckClass(p, name, py_super_class, dict,
                                                 metadict)) {
                Py_DECREF(real_bases);
                Py_DECREF(protocols);
                Py_DECREF(metadict);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                (void)PyObjCClass_UnbuildClass(objc_class);
                return NULL;
            }
        }
    }

    /*
     * add __pyobjc_protocols__ to the class-dict.
     */
    v = PyList_AsTuple(protocols);
    if (v == NULL) {
        Py_DECREF(real_bases);
        Py_DECREF(protocols);
        Py_DECREF(metadict);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        (void)PyObjCClass_UnbuildClass(objc_class);
        return NULL;
    }

    PyDict_SetItemString(dict, "__pyobjc_protocols__", v);
    Py_DECREF(v);

    /*
     * Users can define a __del__ method. We special-case this to
     * avoid triggering the default mechanisms for this method: The
     * method should only be called when the Objective-C side of the
     * instance is deallocated, not whenever the Python proxy is.
     */
    delmethod = PyDict_GetItemString(dict, "__del__");
    if (delmethod == NULL) {
        PyErr_Clear();

    } else {
        Py_INCREF(delmethod);

        if (isCFProxyClass) {
            PyErr_SetString(PyObjCExc_Error,
                            "cannot define __del__ on subclasses of NSCFType");
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;

        } else {
            if (PyDict_DelItemString(dict, "__del__") < 0) {
                if (objc_class != nil) {
                    (void)PyObjCClass_UnbuildClass(objc_class);
                }
                Py_DECREF(protocols);
                Py_DECREF(real_bases);
                Py_DECREF(metadict);
                Py_DECREF(hiddenSelectors);
                Py_DECREF(hiddenClassSelectors);
                return NULL;
            }
        }
    }

    /* Add convenience methods like '__eq__'. Must do it before
     * call to super-class implementation, because '__*' methods
     * are treated specially there.
     */
    old_dict = PyDict_Copy(dict);
    if (old_dict == NULL) {
        if (objc_class != nil) {
            (void)PyObjCClass_UnbuildClass(objc_class);
        }
        Py_DECREF(protocols);
        Py_DECREF(real_bases);
        Py_DECREF(metadict);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        return NULL;
    }

    if (PyObjC_MakeBundleForClass != NULL && PyObjC_MakeBundleForClass != Py_None) {
        PyObject* args[1] = {NULL};

        PyObject* m = PyObject_Vectorcall(PyObjC_MakeBundleForClass, args + 1,
                                          0 | PY_VECTORCALL_ARGUMENTS_OFFSET, NULL);
        if (m == NULL) {
            (void)PyObjCClass_UnbuildClass(objc_class);
            Py_DECREF(old_dict);
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }
        if (PyObjCPythonSelector_Check(m)) {
            ((PyObjCSelector*)m)->sel_class = objc_class;
        }

        r = PyDict_SetItemString(dict, "bundleForClass", m);
        Py_DECREF(m);
        if (r == -1) {
            (void)PyObjCClass_UnbuildClass(objc_class);
            Py_DECREF(old_dict);
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }
    }

    PyTypeObject* metatype;
    if (objc_class != nil) {
        metatype = PyObjCClass_NewMetaClass(objc_class);
        if (metatype == NULL) {
            Py_DECREF(old_dict);
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

        if (PyDict_Update(metatype->tp_dict, metadict) == -1) {
            Py_DECREF(old_dict);
            Py_DECREF(protocols);
            Py_DECREF(real_bases);
            Py_DECREF(metadict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            return NULL;
        }

    } else {
        metatype = Py_TYPE(PyObjC_NSCFTypeClass);
        Py_INCREF(metatype);
    }
    Py_DECREF(metadict);
    metadict = NULL;

    /* call super-class implementation */
    args = Py_BuildValue("(sOO)", name, real_bases, dict);
    if (args == NULL) {
        Py_DECREF(metatype);
        Py_DECREF(real_bases);
        Py_DECREF(protocols);
        Py_DECREF(old_dict);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        return NULL;
    }

    /* The actual superclass might be different due to introduction
     * of magic intermediate classes, therefore explicitly refer to the
     * metatype we just created.
     */
    res = PyType_Type.tp_new(metatype, args, NULL);
    Py_DECREF(metatype);
    if (res == NULL) {
        Py_DECREF(args);
        Py_DECREF(real_bases);
        Py_DECREF(protocols);
        Py_DECREF(old_dict);
        Py_DECREF(hiddenSelectors);
        Py_DECREF(hiddenClassSelectors);
        (void)PyObjCClass_UnbuildClass(objc_class);
        return NULL;
    }
    Py_DECREF(args);
    Py_DECREF(real_bases);
    args       = NULL;
    real_bases = NULL;

    Py_DECREF(protocols);
    protocols = NULL;

    if (objc_class != nil) {
        /* Register the proxy as soon as possible, we can get
         * initialize calls very early on with the ObjC 2.0 runtime.
         */
        PyObjC_RegisterPythonProxy(objc_class, res);

        if (objc_class_register(objc_class, res) < 0) {
            PyObjC_UnregisterPythonProxy(objc_class, res);
            Py_DECREF(res);
            Py_DECREF(old_dict);
            Py_DECREF(hiddenSelectors);
            Py_DECREF(hiddenClassSelectors);
            (void)PyObjCClass_UnbuildClass(objc_class);
            return NULL;
        }

        PyObjCClass_FinishClass(objc_class);
    }

    info        = (PyObjCClassObject*)res;
    info->class = objc_class;
    if (isCFProxyClass) {
        info->class = PyObjCClass_GetClass(PyObjC_NSCFTypeClass);
    }
    info->sel_to_py            = NULL;
    info->dictoffset           = 0;
    info->useKVO               = 0;
    info->delmethod            = delmethod;
    info->hasPythonImpl        = 1;
    info->isCFWrapper          = 0;
    info->isFinal              = final;
    info->hiddenSelectors      = hiddenSelectors;
    info->hiddenClassSelectors = hiddenClassSelectors;
    info->lookup_cache         = NULL;

    var = class_getInstanceVariable(objc_class, "__dict__");
    if (var != NULL) {
        info->dictoffset = ivar_getOffset(var);
    }

    useKVOObj = PyDict_GetItemString(dict, "__useKVO__");
    if (useKVOObj != NULL) {
        info->useKVO = PyObject_IsTrue(useKVOObj);
    } else {
        info->useKVO = PyObjC_UseKVO;
    }

    if (isCFProxyClass) {
        /* Disable automatic KVO on pure CoreFoundation types */
        info->useKVO = 0;
    }
    keys = PyDict_Keys(dict);
    if (keys == NULL) {
        Py_DECREF(old_dict);
        return NULL;
    }

    /* Merge the "difference" to pick up new selectors */
    len = PyList_GET_SIZE(keys);
    for (i = 0; i < len; i++) {
        k = PyList_GET_ITEM(keys, i);
        if (PyDict_GetItem(old_dict, k) == NULL) {
            v = PyDict_GetItem(dict, k);
            if (v != NULL && PyObject_SetAttr(res, k, v) == -1) {
                PyErr_Clear();
            }
        }
    }

    Py_DECREF(keys);
    Py_DECREF(old_dict);

    if (PyObjCClass_CheckMethodList(res, 1) < 0) {
        Py_DECREF(res);
        return NULL;
    }

    /* This is an "extra" ref */
    if (all_python_classes == NULL) {
        all_python_classes = PyList_New(0);
        if (all_python_classes == NULL) {
            Py_FatalError("Cannot create internal list");
        }
    }
    if (PyList_Append(all_python_classes, res) < 0) {
        Py_FatalError("Cannot store generated class");
    }

    Py_INCREF(res);
    return res;
}

static PyObject* _Nullable class_repr(PyObject* obj)
{
    Class cls = PyObjCClass_GetClass(obj);
    if (cls) {
        const char* nm = class_getName(cls);
        if (strstr(nm, "NSCFType") != NULL) {
            return PyUnicode_FromFormat("<core-foundation class %s at %p>",
                                        ((PyTypeObject*)obj)->tp_name, (void*)cls);

        } else {
            return PyUnicode_FromFormat("<objective-c class %s at %p>", nm, (void*)cls);
        }
    } else {
        return PyUnicode_FromFormat("<class %s", ((PyTypeObject*)obj)->tp_name);
    }
}

static void
class_dealloc(PyObject* cls)
{
    char buf[1024];

    snprintf(buf, sizeof(buf), "Deallocating objective-C class %s",
             ((PyTypeObject*)cls)->tp_name);

    fputs(buf, stderr);
    Py_INCREF(cls);
    return;
}

int
PyObjCClass_CheckMethodList(PyObject* start_cls, int recursive)
{
    PyObjCClassObject* info;
    PyObject* _Nullable cls = start_cls;

    info = (PyObjCClassObject*)cls;

    if (info->class == NULL)
        return 0;

    while (info->class != NULL) {

        if (info->generation != PyObjC_MappingCount) {
            int r;
            info->generation = PyObjC_MappingCount;

            r = update_convenience_methods(cls);
            if (r < 0) {
                return -1;
            }
            if (info->sel_to_py) {
                Py_XDECREF(info->sel_to_py);
                info->sel_to_py = PyDict_New();
            }
        }

        if (!recursive)
            break;
        if (class_getSuperclass(info->class) == NULL)
            break;
        /* class_getSuperclass returns Nil only if its argument is Nil */
        cls = PyObjCClass_New((Class _Nonnull)class_getSuperclass(info->class));
        if (cls == NULL) {
            /* Abort checking if the class object cannot be created. Should
             * never happen in practice...
             */
            PyErr_Clear();
            break;
        }

        Py_DECREF(
            cls); /* We don't actually need the reference, convert to a borrowed one */
        info = (PyObjCClassObject*)cls;
    }
    return 0;
}

static PyObject* _Nullable metaclass_dir(PyObject* self)
{
    PyObject*    result;
    Class        cls;
    Method*      methods;
    unsigned int method_count, i;
    char         selbuf[2048];

    /* Start of with keys in __dict__ */
    result = PyDict_Keys(((PyTypeObject*)self)->tp_dict);
    if (result == NULL) {
        return NULL;
    }

    cls = objc_metaclass_locate(self);
    if (cls == NULL) {
        /* This happens for the root of the class tree */
        return result;
    }

    PyObject* self_class = PyObjCClass_ClassForMetaClass(self);
    if (self_class == NULL) {
        Py_DECREF(result);
        return NULL;
    }

    while (cls != NULL) {
        /* Now add all method names */

        /* class_copyMethodList only returns NULL when it sets method_count
         * to 0
         */
        methods =
            (Method* _Nonnull)class_copyMethodList(object_getClass(cls), &method_count);
        for (i = 0; i < method_count; i++) {
            const char* name;
            PyObject*   item;
            SEL         meth_name = method_getName(methods[i]);
            if (meth_name == NULL) {
                /* Ignore methods without a selector */
                continue;
            }

            /* Check if the selector should be hidden */
            if (PyObjCClass_HiddenSelector(self_class, meth_name, YES)) {
                continue;
            }

            name = PyObjC_SELToPythonName(meth_name, selbuf, sizeof(selbuf));
            if (name == NULL) {
                /* Ignore selectors that cannot be converted to a python name.
                 * This should never happen with the size of selbuf.
                 */
                PyErr_Clear();
                continue;
            }

            item = PyUnicode_FromString(name);
            if (item == NULL) {
                free(methods);
                Py_DECREF(self_class);
                Py_DECREF(result);
                return NULL;
            }

            if (PyList_Append(result, item) == -1) {
                free(methods);
                Py_DECREF(self_class);
                Py_DECREF(result);
                Py_DECREF(item);
                return NULL;
            }
            Py_DECREF(item);
        }
        free(methods);

        cls = class_getSuperclass(cls);
    }
    Py_DECREF(self_class);
    return result;
}

/* FIXME: This is a lightly modified version of _type_lookup in objc-object.m, need to
 * merge these */
static inline PyObject* _Nullable _type_lookup(PyTypeObject* tp, PyObject* name)
{
    Py_ssize_t  i, n;
    PyObject *  mro, *base, *dict;
    PyObject*   descr = NULL;
    PyObject*   res;
    const char* sel_name = PyObjC_Unicode_Fast_Bytes(name);
    if (sel_name == NULL) {
        return NULL;
    }
    SEL sel = PyObjCSelector_DefaultSelector(sel_name);

    /* TODO: if sel.startswith('__') and sel.endswith('__'): look_in_runtime = False */

    /* Look in tp_dict of types in MRO */
    mro = tp->tp_mro;
    if (mro == NULL) {
        return NULL;
    }
    res = NULL;
    PyObjC_Assert(PyTuple_Check(mro), NULL);
    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        base = PyTuple_GET_ITEM(mro, i);
        if (PyObjCClass_Check(base)) {
            if (PyObjCClass_CheckMethodList(base, 0) < 0) {
                return NULL;
            }
            dict = ((PyTypeObject*)base)->tp_dict;

        } else if (PyType_Check(base)) {
            dict = ((PyTypeObject*)base)->tp_dict;

        } else {
            return NULL;
        }

        PyObjC_Assert(dict && PyDict_Check(dict), NULL);
        descr = PyDict_GetItem(dict, name);
        if (descr != NULL) {
            break;
        }

        if (PyObject_IsSubclass(base, (PyObject*)&PyObjCMetaClass_Type)) {
            descr = PyObjCMetaClass_TryResolveSelector(base, name, sel);
            if (descr != NULL) {
                break;
            } else if (PyErr_Occurred()) {
                return NULL;
            }
        }
    }

    return descr;
}

static inline PyObject* _Nullable _type_lookup_harder(PyTypeObject* tp, PyObject* name)
/* See function of same name in objc-object.m for an explanation */
{
    Py_ssize_t  i, n;
    PyObject *  mro, *base;
    PyObject*   descr = NULL;
    PyObject*   res;
    const char* name_bytes = PyUnicode_AsUTF8(name);
    if (name_bytes == NULL)
        return NULL;

    /* Look in tp_dict of types in MRO */
    mro = tp->tp_mro;
    if (mro == NULL) {
        return NULL;
    }
    res = NULL;
    PyObjC_Assert(PyTuple_Check(mro), NULL);
    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        Class        cls;
        Method*      methods;
        unsigned int method_count, j;
        char         selbuf[2048];
        const char*  sel_name;

        base = PyTuple_GET_ITEM(mro, i);
        PyObjC_Assert(base != NULL, NULL);

        if (!PyObject_IsSubclass(base, (PyObject*)&PyObjCMetaClass_Type)) {
            continue;
        }
        if (base == (PyObject*)&PyObjCClass_Type
            || base == (PyObject*)&PyObjCMetaClass_Type) {
            /* Root of the PyObjC class tree, these do not refer to an ObjC class */
            continue;
        }

        cls = objc_metaclass_locate(base);
        PyObjC_Assert(cls != Nil, NULL);

        PyObject* class_for_base = PyObjCClass_ClassForMetaClass(base);
        if (class_for_base == NULL) {
            return NULL;
        }

        /* class_copyMethodList only returns NULL when it sets method_count
         * to 0
         */
        methods =
            (Method* _Nonnull)class_copyMethodList(object_getClass(cls), &method_count);
        for (j = 0; j < method_count; j++) {
            Method m         = methods[j];
            SEL    meth_name = method_getName(m);
            if (meth_name == NULL) {
                /* Method without a selector, ignore these */
                continue;
            }

            if (PyObjCClass_HiddenSelector(class_for_base, meth_name, YES)) {
                continue;
            }

            sel_name = PyObjC_SELToPythonName(method_getName(m), selbuf, sizeof(selbuf));
            if (sel_name == NULL) {
                /* Ignore selectors whose name cannot be converted to a python name */
                PyErr_Clear();
                continue;
            }
            if (strcmp(sel_name, name_bytes) == 0) {
                /* Create (unbound) selector */
                const char* encoding = method_getTypeEncoding(m);
                if (encoding == NULL) {
                    Py_DECREF(class_for_base);
                    free(methods);
                    PyErr_SetString(PyObjCExc_Error,
                                    "Native selector with Nil type encoding");
                    return NULL;
                }
                descr = PyObjCSelector_NewNative(cls, method_getName(m), encoding, 1);
                free(methods);
                Py_DECREF(class_for_base);
                if (descr == NULL) {
                    return NULL;
                }

                /* add to __dict__ 'cache' */
                if (PyDict_SetItem(((PyTypeObject*)base)->tp_dict, name, descr) == -1) {
                    Py_DECREF(descr);
                    return NULL;
                }

                /* and return, as a borrowed reference, safe because
                 * it is in tp_dict.
                 */
                Py_DECREF(descr);
                return descr;
            }
        }
        Py_DECREF(class_for_base);
        free(methods);
    }

    /* XXX: just checking... */
    PyObjC_Assert(descr == NULL, NULL);
    return descr;
}

PyObject* _Nullable PyObjCMetaClass_TryResolveSelector(PyObject* base, PyObject* name,
                                                       SEL sel)
{
    Class     cls;
    Method    m;
    PyObject* dict = ((PyTypeObject*)base)->tp_dict;

    Py_BEGIN_ALLOW_THREADS
        @try { /* XXX: Can this raise?, and is it necessary to give up the GIL here? */
            cls = objc_metaclass_locate(base);
            m   = class_getClassMethod(cls, sel);

        } @catch (NSObject* localException) {
            PyObjCErr_FromObjC(localException);
            m = nil;
        }
    Py_END_ALLOW_THREADS
    if (m == nil && PyErr_Occurred()) {
        return NULL;
    }

    if (PyObjCClass_HiddenSelector(PyObjCClass_ClassForMetaClass(base), sel, YES)) {
        return NULL;
    }

    if (m) {
#ifndef PyObjC_FAST_BUT_INEXACT
        int   use = 1;
        Class sup = class_getSuperclass(cls);

        if (sup) {
            Method m_sup = class_getClassMethod(sup, sel);
            if (m_sup == m) {
                use = 0;
            }
        }

        if (!use) {
            return NULL;
        }
#endif

        /* Create (unbound) selector */
        PyObject* result =
            PyObjCSelector_NewNative(cls, sel, method_getTypeEncoding(m), 1);
        if (result == NULL) {
            return NULL;
        }

        /* add to __dict__ 'cache' */
        if (PyDict_SetItem(dict, name, result) == -1) {
            Py_DECREF(result);
            return NULL;
        }

        /* and return, as a borrowed reference */
        Py_DECREF(result);
        return result;
    }
    return NULL;
}

/* FIXME: version of _type_lookup that only looks for instance methods */
static inline PyObject* _Nullable _type_lookup_instance(PyObject*     class_dict,
                                                        PyTypeObject* tp, PyObject* name)
{
    Py_ssize_t i, n;
    PyObject * mro, *base, *dict;
    PyObject*  descr = NULL;
    PyObject*  res;
    SEL        sel = PyObjCSelector_DefaultSelector(PyObjC_Unicode_Fast_Bytes(name));

    /* TODO: if sel.startswith('__') and sel.endswith('__'): look_in_runtime = False */

    /* Look in tp_dict of types in MRO */
    mro = tp->tp_mro;
    if (mro == NULL) {
        return NULL;
    }
    res = NULL;
    PyObjC_Assert(PyTuple_Check(mro), NULL);
    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        base = PyTuple_GET_ITEM(mro, i);
        if (PyType_Check(base)) {
            dict = ((PyTypeObject*)base)->tp_dict;

        } else {
            return NULL;
        }

        descr = PyDict_GetItem(dict, name);
        if (descr != NULL) {
            return descr;
        }

        if (PyObjCClass_Check(base)) {
            /*Class cls = objc_metaclass_locate(base);*/
            Class  cls = PyObjCClass_GetClass(base);
            Method m;

            Py_BEGIN_ALLOW_THREADS
                @try {
                    m = class_getInstanceMethod(cls, sel);

                } @catch (NSObject* localException) {
                    /* Annoyingly enough this can result in callbacks to ObjC
                     * that can raise an exception.
                     */
                    m = NULL;
                }
            Py_END_ALLOW_THREADS

            if (m) {
#ifndef PyObjC_FAST_BUT_INEXACT
                int   use = 1;
                Class sup = class_getSuperclass(cls);
                if (sup) {
                    Method m_sup = class_getInstanceMethod(sup, sel);
                    if (m_sup == m) {
                        use = 0;
                    }
                }
                if (!use)
                    continue;
#endif

                /* Create (unbound) selector */
                PyObject* result =
                    PyObjCSelector_NewNative(cls, sel, method_getTypeEncoding(m), 0);
                if (result == NULL) {
                    return NULL;
                }

                /* add to __dict__ 'cache' */
                if (PyDict_SetItem(class_dict, name, result) == -1) {
                    Py_DECREF(result);
                    return NULL;
                }

                /* and return, as a borrowed reference */
                Py_DECREF(result);
                return result;
            }
        }
    }

    return descr;
}

static inline PyObject* _Nullable _type_lookup_instance_harder(PyObject*     class_dict,
                                                               PyTypeObject* tp,
                                                               PyObject*     name)
{
    Py_ssize_t  i, n;
    PyObject *  mro, *base;
    PyObject*   descr = NULL;
    PyObject*   res;
    const char* name_bytes = PyObjC_Unicode_Fast_Bytes(name);
    if (name_bytes == NULL) {
        return NULL;
    }
    SEL sel = PyObjCSelector_DefaultSelector(name_bytes);

    /* Look in tp_dict of types in MRO */
    mro = tp->tp_mro;
    if (mro == NULL) {
        return NULL;
    }
    res = NULL;
    PyObjC_Assert(PyTuple_Check(mro), NULL);
    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        Class        cls;
        Method*      methods;
        unsigned int method_count, j;
        char         selbuf[2048];
        char*        sel_name;

        base = PyTuple_GET_ITEM(mro, i);
        if (!PyObjCClass_Check(base)) {
            continue;
        }

        cls = PyObjCClass_GetClass(base);

        /* if the result of class_copyMethodList is NULL the method_count
         * is set to 0. The code below will only use the result if method_count
         * is greater than 0.
         */
        methods = (Method* _Nonnull)class_copyMethodList(cls, &method_count);
        for (j = 0; j < method_count; j++) {
            Method m = methods[j];

            sel_name =
                (char*)PyObjC_SELToPythonName(method_getName(m), selbuf, sizeof(selbuf));
            if (sel_name == NULL) {
                /* Ignore methods whose selector cannot be converted */
                PyErr_Clear();
                continue;
            }

            if (strcmp(sel_name, PyObjC_Unicode_Fast_Bytes(name)) == 0) {
                /* Create (unbound) selector */
                const char* encoding = method_getTypeEncoding(m);
                if (encoding == NULL) {
                    PyErr_SetString(PyObjCExc_Error,
                                    "Native selector with Nil type encoding");
                    free(methods);
                    return NULL;
                }
                PyObject* result = PyObjCSelector_NewNative(cls, sel, encoding, 0);
                free(methods);
                if (result == NULL) {
                    return NULL;
                }

                /* add to __dict__ 'cache' */
                if (PyDict_SetItem(class_dict, name, result) == -1) {
                    Py_DECREF(result);
                    return NULL;
                }

                /* and return, as a borrowed reference */
                Py_DECREF(result);
                return result;
            }
        }
        free(methods);
    }

    return descr;
}

static PyObject* _Nullable class_getattro(PyObject* self, PyObject* name)
{
    PyObject*    descr  = NULL;
    PyObject*    result = NULL;
    descrgetfunc f;

    /* Python will look for a number of "private" attributes during
     * normal operations, such as when building subclasses. Avoid a
     * method rescan when that happens.
     *
     * NOTE: This method should be rewritten, copy the version of type()
     *       and modify as needed, that would avoid unnecessary rescans
     *      of superclasses. The same strategy is used in object_getattro.
     *
     * NOTE2: That rewrite should also cause this method to prefer class
     *       methods over instance methods (and documentation should be
     *       added that you shouldn't look up instance methods through the
     *       class).
     *
     */
    if (PyUnicode_Check(name)) {
        if (PyObjC_is_ascii_prefix(name, "__", 2)
            && !PyObjC_is_ascii_string(name, "__dict__")) {
            result = PyType_Type.tp_getattro(self, name);
            if (result != NULL) {
                return result;
            }
            PyErr_Clear();
        }

        if (PyObjC_Unicode_Fast_Bytes(name) == NULL)
            return NULL;

    } else {
        PyErr_Format(PyExc_TypeError,
                     "Attribute name is not a string, but an instance of '%s'",
                     Py_TYPE(name)->tp_name);
        return NULL;
    }
    if (PyObjCClass_CheckMethodList(self, 1) < 0) {
        return NULL;
    }

    descr = _type_lookup(Py_TYPE(self), name);
    if (descr == NULL && PyErr_Occurred()) {
        return NULL;
    }

    f = NULL;
    if (descr != NULL) {
        f = Py_TYPE(descr)->tp_descr_get;
        if (f != NULL && PyDescr_IsData(descr)) {
            result = f(descr, self, (PyObject*)Py_TYPE(self));
            goto done;
        }
    }

    if (strcmp(PyObjC_Unicode_Fast_Bytes(name), "__dict__") == 0) {

        result = ((PyTypeObject*)self)->tp_dict;
        goto done;
    }

    if (descr == NULL) {
        descr = _type_lookup_instance(((PyTypeObject*)self)->tp_dict, (PyTypeObject*)self,
                                      name);
        if (descr != NULL) {
            f = Py_TYPE(descr)->tp_descr_get;
            if (f != NULL) {
                result = f(descr, NULL, self);
                goto done;
            }
        } else if (descr != NULL) {
            result = descr;
            Py_INCREF(result);
            goto done;
        } else if (PyErr_Occurred()) {
            return NULL;
        }
    }

    if (descr == NULL) {
        descr = _type_lookup_harder(Py_TYPE(self), name);
        if (descr != NULL) {
            f = Py_TYPE(descr)->tp_descr_get;
        }
        if (PyErr_Occurred()) {
            return NULL;
        }
    }

    if (descr == NULL) {
        descr = _type_lookup_instance_harder(((PyTypeObject*)self)->tp_dict,
                                             (PyTypeObject*)self, name);
        if (descr != NULL) {
            f = Py_TYPE(descr)->tp_descr_get;
        }
        if (PyErr_Occurred()) {
            /* XXX: can this happen without descr being NULL? */
            return NULL;
        }
    }

    if (f != NULL) {
        result = f(descr, self, (PyObject*)Py_TYPE(self));
        goto done;
    }

    if (descr != NULL) {
        Py_INCREF(descr);
        result = descr;
        goto done;
    }

    /* Try to find the method anyway */
    PyErr_Clear();
    const char* name_bytes = PyObjC_Unicode_Fast_Bytes(name);
    if (name_bytes == NULL) {
        return NULL;
    }
    if (PyObjCClass_HiddenSelector(self, sel_getUid(name_bytes), YES)) {
        PyErr_SetObject(PyExc_AttributeError, name);
        return NULL;
    }

    name_bytes = PyObjC_Unicode_Fast_Bytes(name);
    if (name_bytes == NULL) {
        return NULL;
    }
    result = PyObjCSelector_FindNative(self, name_bytes);

    if (result != NULL) {
        int res = PyDict_SetItem(((PyTypeObject*)self)->tp_dict, name, result);
        PyObjCNativeSelector* x = (PyObjCNativeSelector*)result;

        if (x->base.sel_flags & PyObjCSelector_kCLASS_METHOD) {
            x->base.sel_self = self;
            Py_INCREF(x->base.sel_self);
        }
        if (res < 0) {
            if (PyObjC_Verbose) {
                PySys_WriteStderr("PyObjC[class_getattro]: Cannot "
                                  "add new method to dict:\n");
                PyErr_Print();
            }
            PyErr_Clear();
        }
    }
done:
    return result;
}

static int
class_setattro(PyObject* self, PyObject* name, PyObject* _Nullable value)
{
    int res;
    if (value == NULL) {
        /* delattr(), deny the operation when the name is bound
         * to a selector.
         */
        PyObject* old_value = class_getattro(self, name);
        if (old_value == NULL) {
            PyErr_Clear();
            return PyType_Type.tp_setattro(self, name, value);

        } else if (PyObjCSelector_Check(old_value)) {
            Py_DECREF(old_value);
            PyErr_Format(PyExc_AttributeError, "Cannot remove selector %R in '%s'", name,
                         Py_TYPE(self)->tp_name);

            return -1;
        }
    } else if (PyObjCNativeSelector_Check(value)) {
        PyErr_SetString(PyExc_TypeError, "Assigning native selectors is not supported");
        return -1;

    } else if (((PyObjCClassObject*)self)->isCFWrapper) {
        /* This is a wrapper class for a CoreFoundation type
         * that isn't tollfree bridged. Don't update the
         * Objective-C class because all CF types share the
         * same ObjC class (except for the toll-free bridged
         * ones).
         */

    } else if (PyObjCSelector_Check(value) || PyFunction_Check(value)
               || PyMethod_Check(value)
               || PyObject_TypeCheck(value, &PyClassMethod_Type)) {
        /*
         * Assignment of a function: create a new method in the ObjC
         * runtime.
         */
        PyObject* newVal;
        Method    curMethod;
        Class     curClass;
        int       r;
        BOOL      b;

        newVal = PyObjCSelector_FromFunction(name, value, self, NULL);
        if (newVal == NULL) {
            return -1;
        }
        if (!PyObjCSelector_Check(newVal)) {
            Py_DECREF(newVal);
            PyErr_SetString(PyExc_ValueError, "cannot convert callable to selector");
            return -1;
        }

        if (PyObjCSelector_IsClassMethod(newVal)) {
            curMethod = class_getClassMethod(PyObjCClass_GetClass(self),
                                             PyObjCSelector_GetSelector(newVal));
            curClass  = object_getClass(PyObjCClass_GetClass(self));
        } else {
            curMethod = class_getInstanceMethod(PyObjCClass_GetClass(self),
                                                PyObjCSelector_GetSelector(newVal));
            curClass  = PyObjCClass_GetClass(self);
        }

        if (curMethod) {
            IMP newIMP = PyObjCFFI_MakeIMPForPyObjCSelector((PyObjCSelector*)newVal);
            if (newIMP == NULL) {
                Py_DECREF(newVal);
                return -1;
            }

            method_setImplementation(curMethod, newIMP);

        } else {
            /* XXX: Why use "strdup" here and not the pyobjc_util variant? */
            char* types = strdup(PyObjCSelector_Signature(newVal));

            if (types == NULL) {
                Py_DECREF(newVal);
                return -1;
            }

            IMP newIMP = PyObjCFFI_MakeIMPForPyObjCSelector((PyObjCSelector*)newVal);
            if (newIMP == NULL) {
                free(types);
                Py_DECREF(newVal);
                return -1;
            }
            b = class_addMethod(curClass, PyObjCSelector_GetSelector(newVal), newIMP,
                                types);

            if (!b) {
                free(types);
                Py_DECREF(newVal);
                return -1;
            }
        }

        if (PyObjCClass_HiddenSelector(self, PyObjCSelector_GetSelector(newVal),
                                       PyObjCSelector_IsClassMethod(newVal))) {
            Py_DECREF(newVal);

        } else {
            if (PyObjCSelector_IsClassMethod(newVal)) {
                r = PyDict_SetItem(Py_TYPE(self)->tp_dict, name, newVal);

            } else {
                r = PyDict_SetItem(((PyTypeObject*)self)->tp_dict, name, newVal);
            }

            Py_DECREF(newVal);
            if (r == -1) {
                PyErr_NoMemory();
                return -1;
            }
        }
        return 0;
    }

    res = PyType_Type.tp_setattro(self, name, value);
    return res;
}

static PyObject* _Nullable class_richcompare(PyObject* self, PyObject* other, int op)
{
    Class     self_class;
    Class     other_class;
    int       v;
    PyObject* result;

    if (!PyObjCClass_Check(other)) {
        if (op == Py_EQ) {
            Py_INCREF(Py_False);
            return Py_False;

        } else if (op == Py_NE) {
            Py_INCREF(Py_True);
            return Py_True;

        } else {
            Py_INCREF(Py_NotImplemented);
            return Py_NotImplemented;
        }
    }

    /* This is as arbitrary as the default tp_compare, but nicer for
     * the user
     */
    self_class  = PyObjCClass_GetClass(self);
    other_class = PyObjCClass_GetClass(other);

    if (self_class == other_class) {
        v = 0;

    } else if (!self_class) {
        v = -1;

    } else if (!other_class) {
        v = 1;

    } else {
        switch (op) {
        case Py_EQ:
            /* Classes should only compare equal
             * if they are the same class.
             */
            result = (self_class == other_class) ? Py_True : Py_False;
            Py_INCREF(result);
            return result;

        case Py_NE:
            result = (self_class == other_class) ? Py_False : Py_True;
            Py_INCREF(result);
            return result;
        }

        v = strcmp(class_getName(self_class), class_getName(other_class));
    }

    switch (op) {
    case Py_EQ:
        result = (v == 0) ? Py_True : Py_False;
        break;

    case Py_NE:
        result = (v != 0) ? Py_True : Py_False;
        break;

    case Py_LE:
        result = (v <= 0) ? Py_True : Py_False;
        break;

    case Py_LT:
        result = (v < 0) ? Py_True : Py_False;
        break;

    case Py_GE:
        result = (v >= 0) ? Py_True : Py_False;
        break;

    case Py_GT:
        result = (v > 0) ? Py_True : Py_False;
        break;

    default:
        PyErr_Format(PyExc_TypeError, "Unexpected op=%d in class_richcompare", op);
        return NULL;
    }

    Py_INCREF(result);
    return result;
}

static Py_hash_t
class_hash(PyObject* self)
{
    /* Class equality requires that two classes are the same,
     * using self for the hash is therefore safe.
     */
    return (Py_hash_t)self;
}

PyDoc_STRVAR(
    cls_get_classMethods_doc,
    "The attributes of this field are the class methods of this object. This can\n"
    "be used to force access to a class method.");
static PyObject* _Nullable cls_get_classMethods(PyObject* self, void* _Nullable closure
                                                __attribute__((__unused__)))
{
    return PyObjCMethodAccessor_New(self, 1);
}

PyDoc_STRVAR(
    cls_get_instanceMethods_doc,
    "The attributes of this field are the instance methods of this object. This \n"
    "can be used to force access to an instance method.");
static PyObject* _Nullable cls_get_instanceMethods(PyObject* self, void* _Nullable closure
                                                   __attribute__((__unused__)))
{
    return PyObjCMethodAccessor_New(self, 0);
}

static PyObject* _Nullable cls_get__name__(PyObject* self, void* _Nullable closure
                                           __attribute__((__unused__)))
{
    Class cls = PyObjCClass_GetClass(self);
    if (cls == NULL) {
        return PyUnicode_FromString(((PyTypeObject*)self)->tp_name);

    } else {
        const char* nm = class_getName(cls);
        if (strstr(nm, "NSCFType") != NULL) {
            return PyUnicode_FromString(((PyTypeObject*)self)->tp_name);
        } else {
            return PyUnicode_FromString(nm);
        }
    }
}

PyDoc_STRVAR(cls_version_doc, "get/set the version of a class");
static PyObject* _Nullable cls_get_version(PyObject* self, void* _Nullable closure
                                           __attribute__((__unused__)))
{
    Class cls = PyObjCClass_GetClass(self);
    if (cls == NULL) {
        Py_INCREF(Py_None);
        return Py_None;
    } else {
        return PyLong_FromLong(class_getVersion(cls));
    }
}

static int
cls_set_version(PyObject* self, PyObject* _Nullable newVal,
                void* _Nullable closure __attribute__((__unused__)))
{
    Class cls = PyObjCClass_GetClass(self);
    int   val;
    int   r;

    if (newVal == NULL) {
        PyErr_SetString(PyExc_TypeError, "Cannot delete __version__ attribute");
        return -1;
    }

    r = depythonify_c_value(@encode(int), newVal, &val);
    if (r == -1) {
        return -1;
    }

    class_setVersion(cls, val);
    return 0;
}

static PyObject*
cls_get_useKVO(PyObject* self, void* _Nullable closure __attribute__((__unused__)))
{
    PyObject* result = ((PyObjCClassObject*)self)->useKVO ? Py_True : Py_False;
    Py_INCREF(result);
    return result;
}

static int
cls_set_useKVO(PyObject* self, PyObject* _Nullable newVal,
               void* _Nullable closure __attribute__((__unused__)))
{
    if (newVal == NULL) {
        PyErr_SetString(PyExc_TypeError, "Cannot delete __useKVO__ attribute");
        return -1;
    }

    ((PyObjCClassObject*)self)->useKVO = PyObject_IsTrue(newVal);
    return 0;
}

static PyObject* _Nullable cls_get_final(PyObject* self, void* _Nullable closure
                                         __attribute__((__unused__)))
{
    PyObject* result = ((PyObjCClassObject*)self)->isFinal ? Py_True : Py_False;
    Py_INCREF(result);
    return result;
}

static int
cls_set_final(PyObject* self, PyObject* _Nullable newVal,
              void* _Nullable closure __attribute__((__unused__)))
{
    if (newVal == NULL) {
        PyErr_SetString(PyExc_TypeError, "Cannot delete __objc_final__ attribute");
        return -1;
    }

    ((PyObjCClassObject*)self)->isFinal = PyObject_IsTrue(newVal);
    return 0;
}

static PyGetSetDef class_getset[] = {
    {
        .name = "pyobjc_classMethods",
        .get  = cls_get_classMethods,
        .doc  = cls_get_classMethods_doc,
    },
    {
        .name = "pyobjc_instanceMethods",
        .get  = cls_get_instanceMethods,
        .doc  = cls_get_instanceMethods_doc,
    },
    {
        .name = "__version__",
        .get  = cls_get_version,
        .set  = cls_set_version,
        .doc  = cls_version_doc,
    },
    {
        .name = "__useKVO__",
        .get  = cls_get_useKVO,
        .set  = cls_set_useKVO,
        .doc  = "Use KVO notifications when setting attributes from Python",
    },
    {
        .name = "__objc_final__",
        .get  = cls_get_final,
        .set  = cls_set_final,
        .doc  = "True if the class cannot be subclassed",
    },
    {
        /* Access __name__ through a property: Objective-C name
         * might change due to posing.
         */
        .name = "__name__",
        .get  = cls_get__name__,
    },
    {
        .name = NULL /* SENTINEL */
    }};

static PyObject* _Nullable meth_dir(PyObject* self)
{
    PyObject*    result;
    Class        cls;
    Method*      methods;
    unsigned int method_count, i;
    char         selbuf[2048];

    /* Start of with keys in __dict__ */
    result = PyDict_Keys(((PyTypeObject*)self)->tp_dict);
    if (result == NULL) {
        return NULL;
    }

    cls = PyObjCClass_GetClass(self);

    while (cls != NULL) {
        /* Now add all method names */

        /* class_copyMethodList only returns NULL when it sets method_count
         * to 0
         */
        methods = (Method* _Nonnull)class_copyMethodList(cls, &method_count);
        for (i = 0; i < method_count; i++) {
            char*     name;
            PyObject* item;

            /* Check if the selector should be hidden */
            if (PyObjCClass_HiddenSelector((PyObject*)Py_TYPE(self),
                                           method_getName(methods[i]), NO)) {
                continue;
            }

            name = (char*)PyObjC_SELToPythonName(method_getName(methods[i]), selbuf,
                                                 sizeof(selbuf));
            if (name == NULL) {
                /* Ignore methods whose SEL cannot be converted */
                PyErr_Clear();
                continue;
            }

            item = PyUnicode_FromString(name);
            if (item == NULL) {
                free(methods);
                Py_DECREF(result);
                return NULL;
            }

            if (PyList_Append(result, item) == -1) {
                free(methods);
                Py_DECREF(result);
                Py_DECREF(item);
                return NULL;
            }
            Py_DECREF(item);
        }
        free(methods);

        cls = class_getSuperclass(cls);
    }
    return result;
}

static PyMethodDef metaclass_methods[] = {{.ml_name  = "__dir__",
                                           .ml_meth  = (PyCFunction)metaclass_dir,
                                           .ml_flags = METH_NOARGS,
                                           .ml_doc   = "dir() hook, don't call directly"},
#if PY_VERSION_HEX > 0x03090000
                                          {.ml_name  = "__class_getitem__",
                                           .ml_meth  = (PyCFunction)Py_GenericAlias,
                                           .ml_flags = METH_O,
                                           .ml_doc   = "See PEP 585"},
#endif
                                          {
                                              .ml_name = NULL /* SENTINEL */
                                          }};

static PyMethodDef class_methods[] = {{.ml_name  = "__dir__",
                                       .ml_meth  = (PyCFunction)meth_dir,
                                       .ml_flags = METH_NOARGS,
                                       .ml_doc   = "dir() hook, don't call directly"},

                                      {
                                          .ml_name = NULL /* SENTINEL */
                                      }};

/*
 * This is the class for type(NSObject), and is a subclass of type()
 * with an overridden tp_getattro that is used to dynamically look up
 * class methods.
 */
PyTypeObject PyObjCMetaClass_Type = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0).tp_name = "objc.objc_meta_class",
    .tp_basicsize                                  = sizeof(PyHeapTypeObject),
    .tp_itemsize                                   = sizeof(PyMemberDef),
    .tp_flags                                      = Py_TPFLAGS_DEFAULT,
    .tp_methods                                    = metaclass_methods,
    .tp_base                                       = &PyType_Type,
    .tp_dictoffset                                 = offsetof(PyTypeObject, tp_dict),
};

PyTypeObject PyObjCClass_Type = {
    PyVarObject_HEAD_INIT(&PyObjCMetaClass_Type, 0).tp_name = "objc.objc_class",
    .tp_basicsize                                           = sizeof(PyObjCClassObject),
    .tp_itemsize                                            = 0,
    .tp_dealloc                                             = class_dealloc,
    .tp_repr                                                = class_repr,
    .tp_hash                                                = class_hash,
    .tp_getattro                                            = class_getattro,
    .tp_setattro                                            = class_setattro,
    .tp_flags       = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
    .tp_doc         = class_doc,
    .tp_richcompare = class_richcompare,
    .tp_methods     = class_methods,
    .tp_getset      = class_getset,
    .tp_base        = &PyObjCMetaClass_Type,
    .tp_init        = class_init,
    .tp_new         = class_new,
};

/*
 * Create a new objective-C class  proxy.
 *
 * NOTES:
 * - proxies are subclasses of PyObjCClass_Type
 * - subclass relations in objetive-C are retained in python
 * - this looks a lot like PyObjCClass_Type.tp_new, but it is _not_ the
 *   same!
 *
 * Returns a new reference.
 */
PyObject* _Nullable PyObjCClass_New(Class objc_class)
{
    PyObject*          args;
    PyObject*          dict;
    PyObject*          result;
    PyObject*          bases;
    PyObjCClassObject* info;
    Ivar               var;
    PyObject*          hiddenSelectors;
    PyTypeObject*      metaclass;
    const char*        className;

    if (objc_class == Nil) {
        return NULL;
    }

    result = objc_class_locate(objc_class);
    if (result != NULL) {
        return result;
    }

    if (class_isMetaClass(objc_class)) {
        result = (PyObject*)PyObjCClass_NewMetaClass(objc_class);
        return result;
    }

    hiddenSelectors = PySet_New(NULL);
    if (hiddenSelectors == NULL) {
        return NULL;
    }

    metaclass = PyObjCClass_NewMetaClass(objc_class);
    if (metaclass == NULL) {
        Py_DECREF(hiddenSelectors);
        return NULL;
    }

    dict = PyDict_New();
    PyDict_SetItemString(dict, "__slots__", PyTuple_New(0));

    bases = PyTuple_New(1);

    if (class_getSuperclass(objc_class) == NULL) {
        PyTuple_SET_ITEM(bases, 0, (PyObject*)&PyObjCObject_Type);
        Py_INCREF(((PyObject*)&PyObjCObject_Type));
    } else {
        PyObject* super_class =
            PyObjCClass_New((Class _Nonnull)class_getSuperclass(objc_class));
        if (super_class == NULL) {
            Py_DECREF(hiddenSelectors);
            Py_DECREF(bases);
            return NULL;
        }
        PyTuple_SET_ITEM(bases, 0, super_class);
    }
    args      = PyTuple_New(3);
    className = class_getName(objc_class);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(className));
    PyTuple_SetItem(args, 1, bases);
    PyTuple_SetItem(args, 2, dict);
    bases = NULL;
    dict  = NULL;

    result = PyType_Type.tp_new(metaclass, args, NULL);
    Py_DECREF(args);
    Py_DECREF(metaclass);
    if (result == NULL) {
        Py_DECREF(hiddenSelectors);
        return NULL;
    }

    info                  = (PyObjCClassObject*)result;
    info->class           = objc_class;
    info->sel_to_py       = NULL;
    info->dictoffset      = 0;
    info->useKVO          = 1;
    info->delmethod       = NULL;
    info->hasPythonImpl   = 0;
    info->isCFWrapper     = 0;
    info->isFinal         = 0;
    info->hiddenSelectors = hiddenSelectors;
    info->lookup_cache    = NULL;

    objc_class_register(objc_class, result);

    /*
     * Support the buffer protocol in the wrappers for NSData and
     * NSMutableData, the only two classes where this makes sense.
     */
    if (strcmp(className, "NSMutableData") == 0) {
        ((PyTypeObject*)result)->tp_as_buffer = &nsmutabledata_as_buffer;
        PyType_Modified((PyTypeObject*)result);
        PyType_Ready((PyTypeObject*)result);

    } else if (strcmp(className, "NSData") == 0) {
        ((PyTypeObject*)result)->tp_as_buffer = &nsdata_as_buffer;
        PyType_Modified((PyTypeObject*)result);
        PyType_Ready((PyTypeObject*)result);

    } else if (strcmp(className, "NSBlock") == 0) {
        ((PyTypeObject*)result)->tp_basicsize = sizeof(PyObjCBlockObject);
        PyType_Modified((PyTypeObject*)result);
        PyType_Ready((PyTypeObject*)result);
    }

    if (strcmp(className, "_NSPlaceholderData") == 0) {
        /* Workaround for an issue on macOS 10.15: For some
         * reason the call to class_getInstanceVariable crashes
         * when called early in the process, likely due to an
         * incompletely initialized class.
         *
         * The workaround is hardcoded for this specific class
         * to avoid issues with other magic classes.
         */
        [objc_class class];
    }

    var = class_getInstanceVariable(objc_class, "__dict__");
    if (var != NULL) {
        info->dictoffset = ivar_getOffset(var);
    }

    if (PyObject_SetAttrString(result, "__module__", PyObjCClass_DefaultModule) < 0) {
        PyErr_Clear();
    }

    return result;
}

PyObject* _Nullable PyObjCClass_ListProperties(PyObject* aClass)
{
    Class     cls   = Nil;
    Protocol* proto = nil;

    if (PyObjCClass_Check(aClass)) {
        cls = PyObjCClass_GetClass(aClass);
        if (cls == Nil) {
            return NULL;
        }

    } else if (PyObjCFormalProtocol_Check(aClass)) {
        proto = PyObjCFormalProtocol_GetProtocol(aClass);
        if (proto == nil) {
            return NULL;
        }

    } else {
        PyErr_SetString(PyExc_TypeError,
                        "class must be an Objective-C class or formal protocol");
        return NULL;
    }

    objc_property_t* props;
    unsigned int     propcount, i;
    char             buf[128];

    if (cls == Nil) {
        return NULL;
    }

    PyObject* result = PyList_New(0);
    if (result == NULL) {
        return NULL;
    }

    if (&class_copyPropertyList == NULL) {
        /* System without the 2.0 runtime and hence without
         * native properties
         */
        return result;
    }

    if (cls) {
        props = class_copyPropertyList(cls, &propcount);

    } else {
        props = protocol_copyPropertyList(proto, &propcount);
    }

    if (props == NULL) {
        return result;
    }

    for (i = 0; i < propcount; i++) {
        PyObject*   item;
        PyObject*   v;
        const char* name = property_getName(props[i]);
        const char* attr = property_getAttributes(props[i]);
        const char* e;

        if (!attr)
            continue;

        item = Py_BuildValue("{sssy}", "name", name, "raw_attr", attr);
        if (item == NULL) {
            goto error;
        }
        if (PyList_Append(result, item) == -1) {
            Py_DECREF(item);
            goto error;
        }
        Py_DECREF(item);

        if (*attr != 'T') {
            /* Attribute string doesn't conform to the
             * 2.0 protocol, don't try to process it.
             */
            continue;
        }

        e = PyObjCRT_SkipTypeSpec(attr + 1);
        if (e == NULL) {
            goto error;
        }
        if (e - (attr + 1) > 127) { /* XXX: What does this do??? */
            v = PyObjCBytes_InternFromStringAndSize(attr + 1, e - (attr + 1));
        } else {
            PyObjCRT_RemoveFieldNames(buf, attr + 1);
            v = PyObjCBytes_InternFromString(buf);
        }
        if (v == NULL) {
            goto error;
        }

        if (PyDict_SetItemString(item, "typestr", v) == -1) {
            Py_DECREF(v);
            goto error;
        }
        Py_DECREF(v);
        v = NULL;

        attr = e;
        if (*attr == '"') {
            e = strchr(attr + 1, '"');
            v = PyUnicode_FromStringAndSize(attr + 1, e - (attr + 1));
            if (v == NULL) {
                goto error;
            }
            if (PyDict_SetItemString(item, "classname", v) == -1) {
                Py_DECREF(v);
                goto error;
            }
            Py_DECREF(v);
            v    = NULL;
            attr = e + 1;
        }

        if (*attr++ != ',') {
            /* Value doesn't conform to 2.0 protocol */
            continue;
        }

        while (attr && *attr != '\0') {
            switch (*attr++) {
            case 'R':
                if (PyDict_SetItemString(item, "readonly", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'C':
                if (PyDict_SetItemString(item, "copy", Py_True) < 0) {
                    goto error;
                }
                break;

            case '&':
                if (PyDict_SetItemString(item, "retain", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'N':
                if (PyDict_SetItemString(item, "nonatomic", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'D':
                if (PyDict_SetItemString(item, "dynamic", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'W':
                if (PyDict_SetItemString(item, "weak", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'P':
                if (PyDict_SetItemString(item, "collectable", Py_True) < 0) {
                    goto error;
                }
                break;

            case 'G':
                e = strchr(attr, ',');
                if (e == NULL) {
                    v    = PyBytes_FromString(attr);
                    attr = e;

                } else {
                    v    = PyBytes_FromStringAndSize(attr, e - attr);
                    attr = e;
                }

                if (v == NULL) {
                    goto error;
                }

                if (PyDict_SetItemString(item, "getter", v) < 0) {
                    Py_DECREF(v);
                    goto error;
                }
                break;

            case 'S':
                e = strchr(attr, ',');
                if (e == NULL) {
                    v    = PyBytes_FromString(attr);
                    attr = e;

                } else {
                    v    = PyBytes_FromStringAndSize(attr, e - attr);
                    attr = e;
                }

                if (v == NULL) {
                    goto error;
                }

                if (PyDict_SetItemString(item, "setter", v) < 0) {
                    Py_DECREF(v);
                    goto error;
                }

                break;
            case 'V':
                attr = NULL;
                break;
            }
        }
    }

    free(props);
    props = NULL;

    return result;
error:
    if (props) {
        free(props);
    }
    Py_XDECREF(result);
    return NULL;
}

Class _Nullable PyObjCClass_GetClass(PyObject* cls)
{
    if (PyObjCClass_Check(cls)) {
        /* XXX: This may return Nil without setting an error, check all callers */
        return ((PyObjCClassObject*)cls)->class;

    } else if (PyObjCMetaClass_Check(cls)) {
        Class result = objc_metaclass_locate(cls);
        if (result == Nil) {
            PyErr_Format(PyObjCExc_InternalError, "Cannot find class for meta class %R",
                         cls);
            return Nil;
        }
        return result;

    } else {
        PyErr_Format(PyObjCExc_InternalError,
                     "PyObjCClass_GetClass called for non-class (%s)",
                     Py_TYPE(cls)->tp_name);
        return Nil;
    }
}

PyObject* _Nullable PyObjCClass_FindSelector(PyObject* cls, SEL selector,
                                             BOOL class_method)
{
    PyObjCClassObject* info;
    PyObject*          result;

    if (!PyObjCClass_Check(cls)) {
        PyErr_Format(PyObjCExc_InternalError,
                     "PyObjCClass_GetClass called for non-class (%s)",
                     Py_TYPE(cls)->tp_name);
        return NULL;
    }

    if (PyObjCClass_CheckMethodList(cls, 1) < 0) {
        return NULL;
    }

    info = (PyObjCClassObject*)cls;
    if (info->sel_to_py == NULL) {
        info->sel_to_py = PyDict_New();
        if (info->sel_to_py == NULL) {
            return NULL;
        }
    }

    if (PyObjCClass_HiddenSelector(cls, selector, class_method)) {
        PyErr_Format(PyExc_AttributeError, "No selector %s", sel_getName(selector));
        PyDict_SetItemString(info->sel_to_py, (char*)sel_getName(selector), Py_None);
        return NULL;
    }

    /* First check the cache */

    result = PyDict_GetItemString(info->sel_to_py, (char*)sel_getName(selector));
    if (result != NULL) {
        if (result == Py_None) {
            /* negative cache entry */
            PyErr_Format(PyExc_AttributeError, "No selector %s", sel_getName(selector));
            return NULL;
        }

        Py_INCREF(result);
        return result;
    }

    /* Not in the cache. Walk the MRO to check
     * every method object.
     *
     * (We could also generate the most likely
     * python name and check that, but the most
     * likely reason we're called is that this
     * method doesn't exist or isn't good enough)
     */

    PyObject*  mro = ((PyTypeObject*)cls)->tp_mro;
    Py_ssize_t i, n;

    n = PyTuple_GET_SIZE(mro);
    for (i = 0; i < n; i++) {
        PyObject* c = PyTuple_GET_ITEM(mro, i);

        if (!PyObjCClass_Check(c)) {
            continue;
        }

        PyObject* dict;

        if (class_method) {
            dict = Py_TYPE(c)->tp_dict;
        } else {
            dict = ((PyTypeObject*)c)->tp_dict;
        }

        PyObject*  value;
        Py_ssize_t pos = 0;

        while (PyDict_Next(dict, &pos, NULL, &value)) {
            if (!PyObjCSelector_Check(value))
                continue;

            if (sel_isEqual(PyObjCSelector_GetSelector(value), selector)) {
                PyDict_SetItemString(info->sel_to_py, (char*)sel_getName(selector),
                                     value);
                Py_INCREF(value);
                return value;
            }
        }
        {
            char      selbuf[2048];
            char*     name;
            PyObject* py_name;
            name = PyObjC_SELToPythonName(selector, selbuf, sizeof(selbuf));
            if (!name) {
                PyErr_Clear();
                continue;
            }

            py_name = PyUnicode_FromString(name);
            if (!py_name) {
                PyErr_Clear();
                continue;
            }

            if (class_method) {
                value = PyObjCMetaClass_TryResolveSelector((PyObject*)Py_TYPE(c), py_name,
                                                           selector);
            } else {
                value = PyObjCClass_TryResolveSelector(c, py_name, selector);
            }
            Py_DECREF(py_name);
            if (value != NULL) {
                Py_INCREF(value);
                return value;
            } else if (PyErr_Occurred()) {
                return NULL;
            }
        }
    }

    /* If all else fails, ask the actual class (getattro also does this) */
    result = PyObjCSelector_FindNative(cls, sel_getName(selector));
    if (result) {
        return result;
    }

    PyErr_Format(PyExc_AttributeError, "No selector %s", sel_getName(selector));
    PyDict_SetItemString(info->sel_to_py, (char*)sel_getName(selector), Py_None);
    return NULL;
}

Py_ssize_t
PyObjCClass_DictOffset(PyObject* cls)
{
    return ((PyObjCClassObject*)cls)->dictoffset;
}

PyObject* _Nullable PyObjCClass_GetDelMethod(PyObject* cls)
{
    PyObjCClassObject* info;
    info = (PyObjCClassObject*)cls;
    Py_XINCREF(info->delmethod);
    return info->delmethod;
}

void
PyObjCClass_SetDelMethod(PyObject* cls, PyObject* m)
{
    PyObjCClassObject* info;
    info = (PyObjCClassObject*)cls;
    Py_XINCREF(m);
    Py_XDECREF(info->delmethod);
    info->delmethod = m;
}

int
PyObjCClass_HasPythonImplementation(PyObject* cls)
{
    PyObjCClassObject* info;
    info = (PyObjCClassObject*)cls;
    return info->hasPythonImpl;
}

/*!
 * @function update_convenience_methods
 * @abstract Update the convenience methods for a class
 * @param cls  An Objective-C class wrapper
 * @result Returns -1 on error, 0 on success
 * @discussion
 *     This function calls the PyObjC_ClassExtender function (if one is
 *     registered) and then updates the class __dict__.
 *
 *     NOTE: We change the __dict__ using a setattro function because the type
 *     doesn't notice the existence of new special methods otherwise.
 *
 *     NOTE2: We use PyType_Type.tp_setattro instead of PyObject_SetAttr because
 *     the tp_setattro of Objective-C class wrappers does not allow some of
 *     the assignments we do here.
 */
static int
update_convenience_methods(PyObject* cls)
{
    PyObject*  res;
    PyObject*  dict;
    PyObject*  k;
    PyObject*  v;
    Py_ssize_t pos;

    if (PyObjC_ClassExtender == NULL || PyObjC_ClassExtender == Py_None || cls == NULL)
        return 0;

    if (!PyObjCClass_Check(cls)) {
        PyErr_SetString(PyExc_TypeError, "not a class");
        return -1;
    }

    dict = PyDict_New();
    if (dict == NULL) {
        return -1;
    }

    PyObject* args[3] = {NULL, cls, dict};

    res = PyObject_Vectorcall(PyObjC_ClassExtender, args + 1,
                              2 | PY_VECTORCALL_ARGUMENTS_OFFSET, NULL);
    if (res == NULL) {
        return -1;
    }
    Py_DECREF(res);

    pos = 0;
    while (PyDict_Next(dict, &pos, &k, &v)) {
        if (PyUnicode_Check(k)) {
            if (PyObjC_is_ascii_string(k, "__dict__")
                || PyObjC_is_ascii_string(k, "__bases__")
                || PyObjC_is_ascii_string(k, "__slots__")
                || PyObjC_is_ascii_string(k, "__mro__")) {

                continue;
            }

        } else {
            if (PyDict_SetItem(((PyTypeObject*)cls)->tp_dict, k, v) == -1) {
                PyErr_Clear();
            }
            continue;
        }

        if (PyType_Type.tp_setattro(cls, k, v) == -1) {
            PyErr_Clear();
            continue;
        }
    }

    Py_DECREF(dict);
    return 0;
}

PyObject* _Nullable PyObjCClass_ClassForMetaClass(PyObject* meta)
{
    if (meta == NULL)
        return NULL;

    Class real_class = objc_metaclass_locate(meta);
    if (real_class == Nil) {
        return NULL;
    }
    return PyObjCClass_New(real_class);
}

int
PyObjCClass_AddMethods(PyObject* classObject, PyObject** methods, Py_ssize_t methodCount)
{
    Class                 targetClass;
    Py_ssize_t            methodIndex;
    int                   r;
    struct PyObjC_method* methodsToAdd;
    size_t                curMethodIndex;
    struct PyObjC_method* classMethodsToAdd;
    size_t                curClassMethodIndex;
    PyObject*             extraDict = NULL;
    PyObject*             metaDict  = NULL;

    targetClass = PyObjCClass_GetClass(classObject);
    if (targetClass == NULL) {
        return -1;
    }

    if (methodCount == 0) {
        return 0;
    }

    extraDict = PyDict_New();
    if (extraDict == NULL) {
        return -1;
    }

    metaDict = PyDict_New();
    if (metaDict == NULL) {
        Py_DECREF(extraDict);
        return -1;
    }

    methodsToAdd = PyMem_Malloc(sizeof(*methodsToAdd) * methodCount);
    if (methodsToAdd == NULL) {
        Py_DECREF(extraDict);
        Py_DECREF(metaDict);
        PyErr_NoMemory();
        return -1;
    }

    classMethodsToAdd = PyMem_Malloc(sizeof(*methodsToAdd) * methodCount);
    if (classMethodsToAdd == NULL) {
        Py_DECREF(extraDict);
        Py_DECREF(metaDict);
        PyMem_Free(methodsToAdd);
        PyErr_NoMemory();
        return -1;
    }

    curMethodIndex      = 0;
    curClassMethodIndex = 0;

    for (methodIndex = 0; methodIndex < methodCount; methodIndex++) {
        PyObject*             aMethod = methods[methodIndex];
        PyObject*             name;
        struct PyObjC_method* objcMethod;

        if (PyObjCNativeSelector_Check(aMethod)) {
            PyErr_SetString(PyExc_TypeError, "Cannot add a native selector to other "
                                             "classes");
            goto cleanup_and_return_error;
        }

        aMethod = PyObjCSelector_FromFunction(NULL, aMethod, classObject, NULL);
        if (aMethod == NULL) {
            PyErr_Format(PyExc_TypeError, "All objects in methodArray must be of "
                                          "type <objc.selector>, <function>, "
                                          " <method> or <classmethod>");
            goto cleanup_and_return_error;
        }

        /* install in methods to add */
        if (PyObjCSelector_IsClassMethod(aMethod)) {
            objcMethod = classMethodsToAdd + curClassMethodIndex++;

        } else {
            objcMethod = methodsToAdd + curMethodIndex++;
        }

        objcMethod->name = PyObjCSelector_GetSelector(aMethod);
        objcMethod->type = strdup(PyObjCSelector_Signature(aMethod));

        if (PyObjC_RemoveInternalTypeCodes((char*)(objcMethod->type)) == -1) {
            goto cleanup_and_return_error;
        }
        if (objcMethod->type == NULL) {
            goto cleanup_and_return_error;
        }

        IMP imp = PyObjCFFI_MakeIMPForPyObjCSelector((PyObjCSelector*)aMethod);
        if (imp == NULL) {
            goto cleanup_and_return_error;
        }
        objcMethod->imp = imp;

        name = PyObject_GetAttrString(aMethod, "__name__");

        if (PyBytes_Check(name)) {
            /* XXX: Why support bytes here? */
            PyObject* t =
                PyUnicode_Decode(PyBytes_AsString(name), PyBytes_Size(name), NULL, NULL);
            if (t == NULL) {
                Py_DECREF(name);
                name = NULL;
                Py_DECREF(aMethod);
                aMethod = NULL;
                goto cleanup_and_return_error;
            }
            Py_DECREF(name);
            name = t;
        }

        if (PyObjCSelector_IsHidden(aMethod)) {
            r = PyObjCClass_SetHidden(classObject, objcMethod->name,
                                      PyObjCSelector_IsClassMethod(aMethod),
                                      (PyObject*)PyObjCSelector_GetMetadata(aMethod));
            if (r == -1) {
                goto cleanup_and_return_error;
            }
        }

        r = 0;
        if (!PyObjCClass_HiddenSelector(classObject, objcMethod->name,
                                        PyObjCSelector_IsClassMethod(aMethod))) {
            if (PyObjCSelector_IsClassMethod(aMethod)) {
                r = PyDict_SetItem(metaDict, name, aMethod);

            } else {
                r = PyDict_SetItem(extraDict, name, aMethod);
            }
        }

        Py_DECREF(name);
        name = NULL;
        Py_DECREF(aMethod);
        aMethod = NULL;

        if (r == -1) {
            goto cleanup_and_return_error;
        }
    }

    /* add the methods */
    if (curMethodIndex != 0) {
        PyObjC_class_addMethodList(targetClass, methodsToAdd, (unsigned)curMethodIndex);
    }

    PyMem_Free(methodsToAdd);
    methodsToAdd = NULL;
    if (curClassMethodIndex != 0) {
        /* object_getClass will only return Nil if its argument is nil */
        PyObjC_class_addMethodList((Class _Nonnull)object_getClass(targetClass),
                                   classMethodsToAdd, (unsigned)curClassMethodIndex);
    }

    PyMem_Free(classMethodsToAdd);
    classMethodsToAdd = NULL;

    r = PyDict_Merge(((PyTypeObject*)classObject)->tp_dict, extraDict, 1);
    if (r == -1)
        goto cleanup_and_return_error;

    r = PyDict_Merge(Py_TYPE(classObject)->tp_dict, metaDict, 1);
    if (r == -1)
        goto cleanup_and_return_error;

    Py_DECREF(extraDict);
    extraDict = NULL;
    Py_DECREF(metaDict);
    metaDict = NULL;

    return 0;

cleanup_and_return_error:
    Py_XDECREF(metaDict);
    Py_XDECREF(extraDict);
    if (methodsToAdd) {
        /* XXX: This should also clear entries */
        PyMem_Free(methodsToAdd);
    }
    if (classMethodsToAdd) {
        /* XXX: This should also clear entries */
        PyMem_Free(classMethodsToAdd);
    }
    return -1;
}

NS_ASSUME_NONNULL_END
