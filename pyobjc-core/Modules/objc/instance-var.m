#include "pyobjc.h"

/*
 * descriptor objc_ivar
 *
 * We start of with a descriptor object that allows the user to access
 * (read and write) objective-C instance variables.
 *
 * These descriptors are used in two places:
 * 1) the wrapper for objective-C classes and objects use these to provide
 *    access to existing instance variables
 * 2) the user can define new instance variables (most likely 'outlets') when
 *    defining subclasses of objective-C classes.
 */

NS_ASSUME_NONNULL_BEGIN

static void
ivar_dealloc(PyObject* _ivar)
{
    PyObjCInstanceVariable* ivar = (PyObjCInstanceVariable*)_ivar;
    if (ivar->name) {
        PyMem_Free(ivar->name);
    }
    if (ivar->type) {
        PyMem_Free(ivar->type);
    }
    Py_TYPE(ivar)->tp_free((PyObject*)ivar);
}

static PyObject* _Nullable ivar_repr(PyObject* _self)
{
    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;
    if (self->isOutlet) {
        if (self->name) {
            return PyUnicode_FromFormat("<IBOutlet %s>", self->name);
        } else {
            return PyUnicode_FromString("<IBOutlet>");
        }

    } else {
        if (self->name) {
            return PyUnicode_FromFormat("<instance-variable %s>", self->name);
        } else {
            return PyUnicode_FromString("<instance-variable>");
        }
    }
}

static PyObject* _Nullable ivar_descr_get(PyObject* _self, PyObject* _Nullable obj,
                                          PyObject* type __attribute__((__unused__)))
{
    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;
    Ivar                    var;
    id                      objc;
    PyObject*               res;

    if (!obj) {
        /* Getting the instance variable from a class, return the descriptor itself
         * to make it easier to introspect.
         */
        Py_INCREF(_self);
        return _self;
    }

    if (!obj || PyObjCClass_Check(obj)) {
        /* XXX: Not sure if this is ever true... */
        PyErr_SetString(PyExc_TypeError, "Cannot access Objective-C instance-variables "
                                         "through class");
        return NULL;
    }

    if (!PyObjCObject_Check(obj)) {
        PyErr_SetString(PyExc_TypeError, "objc.ivar descriptor on a plain Python object");
        return NULL;
    }

    objc = PyObjCObject_GetObject(obj);
    if (objc == NULL) {
        PyErr_SetString(PyExc_TypeError,
                        "Cannot access Objective-C instance-variables of NULL");
        return NULL;
    }

    if (self->name == NULL) {
        PyErr_SetString(PyExc_TypeError, "Using unnamed instance variable");
        return NULL;
    }

    var = class_getInstanceVariable(object_getClass(objc), self->name);
    if (var == NULL) {
        PyErr_Format(
            PyExc_RuntimeError,
            "objc.ivar descriptor for non-existing instance variable '%s' in class '%s'",
            self->name, class_getName(object_getClass(objc)));
        return NULL;
    }

    if (self->isSlot) {
        res = *(PyObject**)(((char*)objc) + ivar_getOffset(var));

        if (res == NULL) {
            PyErr_Format(PyExc_AttributeError, "No attribute %s\n", ivar_getName(var));
        } else {
            Py_INCREF(res);
        }

    } else {
        const char* encoding = ivar_getTypeEncoding(var);

        if (encoding == NULL) {
            PyErr_SetString(PyObjCExc_Error, "Cannot extract type encoding from ivar");
            return NULL;
        }

        if (encoding[0] == _C_ID) {
            /* An object */
            id value = object_getIvar(objc, var);
            res      = pythonify_c_value(encoding, &value);
        } else {
            res = pythonify_c_value(encoding, ((char*)objc) + ivar_getOffset(var));
        }
    }
    return res;
}

static int
ivar_descr_set(PyObject* _self, PyObject* _Nullable obj, PyObject* _Nullable value)
{
    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;
    Ivar                    var;
    id                      objc;
    Py_ssize_t              size;
    int                     res;

    if (value == NULL && !self->isSlot) {
        PyErr_SetString(PyExc_TypeError, "Cannot delete Objective-C instance variables");
        return -1;
    }

    if (!obj || PyObjCClass_Check(obj)) {
        PyErr_SetString(PyExc_TypeError, "Cannot set Objective-C instance-variables "
                                         "through class");
        return -1;
    }

    if (!PyObjCObject_Check(obj)) {
        PyErr_SetString(PyExc_TypeError, "objc.ivar descriptor on a plain Python object");
        return -1;
    }

    objc = PyObjCObject_GetObject(obj);
    if (objc == NULL) {
        PyErr_SetString(PyExc_TypeError,
                        "Cannot access Objective-C instance-variables of NULL");
        return -1;
    }

    if (self->name == NULL) {
        PyErr_SetString(PyExc_TypeError, "Using unnamed instance variable");
        return -1;
    }

    if (self->ivar == NULL) {
        var = class_getInstanceVariable(object_getClass(objc), self->name);
        if (var == NULL) {
            PyErr_SetString(PyExc_RuntimeError,
                            "objc_ivar descriptor for non-existing instance "
                            "variable");
            return -1;
        }
        self->ivar = var;
    } else {
        var = self->ivar;
    }

    // NSString* ocName = [NSString stringWithUTF8String:self->name];
    // [objc willChangeValueForKey:ocName];

    if (self->isSlot) {
        PyObject** slotval = (PyObject**)(((char*)objc) + ivar_getOffset(var));
        Py_XINCREF(value);
        Py_XDECREF(*slotval);
        *slotval = value;

        // [objc didChangeValueForKey:ocName];
        return 0;
    }

    if (strcmp(ivar_getTypeEncoding(var), @encode(id)) == 0) {
        /* Automagically manage refcounting of instance variables */
        id new_value;

        res = depythonify_c_value(@encode(id), value, &new_value);
        if (res == -1) {
            // [objc didChangeValueForKey:ocName];
            return -1;
        }

        if (!self->isOutlet) {
            Py_BEGIN_ALLOW_THREADS
                @try {
                    id old_value = object_getIvar(objc, var);
                    [new_value retain];
                    [old_value release];
                } @catch (NSObject* localException) {
                    NSLog(@"PyObjC: ignoring exception during attribute replacement: %@",
                          localException);
                }
            Py_END_ALLOW_THREADS
        }

        object_setIvar(objc, var, new_value);
        // [objc didChangeValueForKey:ocName];

        return 0;
    }

    size = PyObjCRT_SizeOfType(ivar_getTypeEncoding(var));
    if (size == -1) {
        // [objc didChangeValueForKey:ocName];
        return -1;
    }
    res = depythonify_c_value(ivar_getTypeEncoding(var), value,
                              (void*)(((char*)objc) + ivar_getOffset(var)));
    if (res == -1) {
        // [objc didChangeValueForKey:ocName];
        return -1;
    }

    // [objc didChangeValueForKey:ocName];
    return 0;
}

static int
ivar_init(PyObject* _self, PyObject* _Nullable args, PyObject* _Nullable kwds)
{
    static char*            keywords[]  = {"name", "type", "isOutlet", NULL};
    PyObjCInstanceVariable* self        = (PyObjCInstanceVariable*)_self;
    char*                   name        = NULL;
    char*                   type        = @encode(id);
    PyObject*               isOutletObj = NULL;

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "|syO:objc_ivar", keywords, &name, &type,
                                     &isOutletObj)) {
        return -1;
    }

    if (name) {
        self->name = PyObjCUtil_Strdup(name);
        if (self->name == NULL) {
            return -1;
        }

    } else {
        self->name = NULL;
    }

    self->type = PyObjCUtil_Strdup(type);
    if (self->type == NULL) {
        if (name) {
            PyMem_Free(self->name);
        }
        return -1;
    }

    if (isOutletObj) {
        self->isOutlet = PyObject_IsTrue(isOutletObj);

    } else {
        self->isOutlet = 0;
    }

    self->ivar   = NULL;
    self->isSlot = 0;

    return 0;
}

static PyObject* _Nullable ivar_class_setup(PyObject* _self, PyObject* _Nullable args,
                                            PyObject* _Nullable kwds)
{
    static char* keywords[] = {"name", "class_dict", "instance_method_list",
                               "class_method_list", NULL};

    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;
    char*                   name;
    PyObject*               class_dict;
    PyObject*               instance_method_list;
    PyObject*               class_method_list;

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "sO!O!O!", keywords, &name, &PyDict_Type,
                                     &class_dict, &PySet_Type, &instance_method_list,
                                     &PySet_Type, &class_method_list)) {

        return NULL;
    }

    if (self->name == NULL) {
        self->name = PyObjCUtil_Strdup(name);
    }

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject* _Nullable ivar_add_attribute(PyObject* self, PyObject* _Nullable args)
{
    PyObject* name;
    PyObject* value;

    if (!PyArg_ParseTuple(args, "UO", &name, &value)) {
        return NULL;
    }

    /* XXX: This is suboptimal, convert this type to a heap type instead */
    /* XXX: This uses a private CPython API function */
    if (_PyObject_GenericSetAttrWithDict(self, name, value, NULL) == -1) {
        return NULL;
    }

    PyType_Modified((PyTypeObject*)self);

    Py_INCREF(Py_None);
    return Py_None;
}

static PyMethodDef ivar_methods[] = {
    {
        .ml_name  = "__pyobjc_class_setup__",
        .ml_meth  = (PyCFunction)ivar_class_setup,
        .ml_flags = METH_VARARGS | METH_KEYWORDS,
    },
    {
        .ml_name  = "_add_attribute",
        .ml_meth  = (PyCFunction)ivar_add_attribute,
        .ml_flags = METH_VARARGS | METH_CLASS,
        .ml_doc   = "_add_attribute(name, value)\n" CLINIC_SEP "\n"
                    "(private) add a named attribute to the class",

    },

    {
        .ml_name = NULL /* SENTINEL */
    }};

PyDoc_STRVAR(
    ivar_doc,
    "ivar(name, type='@', isOutlet=False) -> instance-variable\n" CLINIC_SEP "\n"
    "Creates a descriptor for accessing an Objective-C instance variable.\n\n"
    "This should only be used in the definition of Objective-C subclasses, and\n"
    "will then automatically define the instance variable in the objective-C side.\n"
    "\n"
    "'type' is optional and should be a signature string.\n"
    "\n"
    "The name is optional in class definitions and will default to the name the\n"
    "value is assigned to");

PyDoc_STRVAR(ivar_typestr_doc, "The Objective-C type encoding");
static PyObject* _Nullable ivar_get_typestr(PyObject* _self, void* _Nullable closure
                                            __attribute__((__unused__)))
{
    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;

    return PyBytes_FromString(self->type);
}

PyDoc_STRVAR(ivar_name_doc, "The Objective-C name");
static PyObject* _Nullable ivar_get_name(PyObject* _self, void* _Nullable closure
                                         __attribute__((__unused__)))
{
    PyObjCInstanceVariable* self = (PyObjCInstanceVariable*)_self;

    if (self->name) {
        return PyUnicode_FromString(self->name);
    } else {
        Py_INCREF(Py_None);
        return Py_None;
    }
}

PyDoc_STRVAR(ivar_isOutlet_doc, "True if the instance variable is an IBOutlet");
static PyObject* _Nullable ivar_get_isOutlet(PyObject* _self, void* _Nullable closure
                                             __attribute__((__unused__)))
{
    PyObjCInstanceVariable* self   = (PyObjCInstanceVariable*)_self;
    PyObject*               result = self->isOutlet ? Py_True : Py_False;
    Py_INCREF(result);
    return result;
}

PyDoc_STRVAR(ivar_isSlot_doc, "True if the instance variable is a Python slot");
static PyObject* _Nullable ivar_get_isSlot(PyObject* _self, void* _Nullable closure
                                           __attribute__((__unused__)))
{
    PyObjCInstanceVariable* self   = (PyObjCInstanceVariable*)_self;
    PyObject*               result = self->isSlot ? Py_True : Py_False;
    Py_INCREF(result);
    return result;
}

static PyGetSetDef ivar_getset[] = {{
                                        .name = "__typestr__",
                                        .get  = ivar_get_typestr,
                                        .doc  = ivar_typestr_doc,
                                    },
                                    {
                                        .name = "__name__",
                                        .get  = ivar_get_name,
                                        .doc  = ivar_name_doc,
                                    },
                                    {
                                        .name = "__isOutlet__",
                                        .get  = ivar_get_isOutlet,
                                        .doc  = ivar_isOutlet_doc,
                                    },
                                    {
                                        .name = "__isSlot__",
                                        .get  = ivar_get_isSlot,
                                        .doc  = ivar_isSlot_doc,
                                    },
                                    {
                                        .name = NULL /* SENTINEL */
                                    }};

PyTypeObject PyObjCInstanceVariable_Type = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0).tp_name = "ivar",
    .tp_basicsize                                  = sizeof(PyObjCInstanceVariable),
    .tp_itemsize                                   = 0,
    .tp_dealloc                                    = ivar_dealloc,
    .tp_repr                                       = ivar_repr,
    .tp_getattro                                   = PyObject_GenericGetAttr,
    .tp_flags                                      = Py_TPFLAGS_DEFAULT,
    .tp_doc                                        = ivar_doc,
    .tp_methods                                    = ivar_methods,
    .tp_getset                                     = ivar_getset,
    .tp_descr_get                                  = ivar_descr_get,
    .tp_descr_set                                  = ivar_descr_set,
    .tp_init                                       = ivar_init,
    .tp_alloc                                      = PyType_GenericAlloc,
    .tp_new                                        = PyType_GenericNew,
};

PyObject* _Nullable PyObjCInstanceVariable_New(const char* name)
{
    PyObject* result;

    result = PyObjCInstanceVariable_Type.tp_alloc(&PyObjCInstanceVariable_Type, 0);
    if (result == NULL) { // LCOV_BR_EXCL_LINE
        return NULL;      // LCOV_EXCL_LINE
    }

    ((PyObjCInstanceVariable*)result)->type = PyObjCUtil_Strdup("");
    if (((PyObjCInstanceVariable*)result)->type == NULL) { // LCOV_BR_EXCL_LINE
        // LCOV_EXCL_START
        Py_DECREF(result);
        return NULL;
        // LCOV_EXCL_STOP
    }

    ((PyObjCInstanceVariable*)result)->isOutlet = 0;
    ((PyObjCInstanceVariable*)result)->isSlot   = 0;
    ((PyObjCInstanceVariable*)result)->ivar     = 0;
    ((PyObjCInstanceVariable*)result)->name     = PyObjCUtil_Strdup(name);

    if (((PyObjCInstanceVariable*)result)->name == NULL) { // LCOV_BR_EXCL_LINE
        // LCOV_EXCL_START
        Py_DECREF(result);
        return NULL;
        // LCOV_EXCL_STOP
    }
    return result;
}

NS_ASSUME_NONNULL_END
