#include "pyobjc.h"

NS_ASSUME_NONNULL_BEGIN

/* A basic wrapper for C's "FILE*"
 * that implements a usable API.
 */

struct file_object {
    PyObject_HEAD

    FILE* _Nullable fp;
};

static PyObject* _Nullable file_new(PyTypeObject* type __attribute__((__unused__)),
                                    PyObject* _Nullable args, PyObject* _Nullable kwds)
{
    static char* keywords[] = {"path", "mode", NULL};
    FILE*        fp;
    char*        fname;
    char*        mode;

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "ss", keywords, &fname, &mode)) {
        return NULL;
    }

    fp = fopen(fname, mode);

    if (fp == NULL) {
        return PyErr_SetFromErrno(PyExc_OSError);
    }

    return FILE_create(fp);
}

static void
file_dealloc(PyObject* self)
{
    /* Don't close the file, we don't own the
     * FILE* reference.
     */
    PyObject_Free(self);
}

static PyObject* _Nullable file_close(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Closing closed file");
        return NULL;
    }

    if (fclose(self->fp) < 0) {
        return PyErr_SetFromErrno(PyExc_OSError);
    }

    self->fp = NULL;

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject* _Nullable file_flush(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    int                 result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    result = fflush(self->fp);
    if (result != 0) {
        return PyErr_SetFromErrno(PyExc_OSError);
    }

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject* _Nullable file_errors(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    int                 result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    result = ferror(self->fp);

    return PyBool_FromLong(result);
}

static PyObject* _Nullable file_at_eof(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    int                 result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    result = feof(self->fp);

    return PyBool_FromLong(result);
}

static PyObject* _Nullable file_tell(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    long                offset;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    offset = ftell(self->fp);
    if (offset < 0) {
        return PyErr_SetFromErrno(PyExc_OSError);
    }

    return PyLong_FromLong(offset);
}

static PyObject* _Nullable file_seek(PyObject* _self, PyObject* args, PyObject* kwds)
{
    static char* keywords[] = {"offset", "whence", NULL};

    struct file_object* self = (struct file_object*)_self;
    Py_ssize_t          offset;
    int                 whence;
    long                result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "ni", keywords, &offset, &whence)) {
        return NULL;
    }

    result = fseek(self->fp, offset, whence);
    if (result < 0) {
        return PyErr_SetFromErrno(PyExc_OSError);
    }

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject* _Nullable file_fileno(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    int                 fd;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    fd = fileno(self->fp);
    /* According to the manpage this function cannot fail */

    return PyLong_FromLong(fd);
}

static PyObject* _Nullable file_write(PyObject* _self, PyObject* args, PyObject* kwds)
{
    static char* keywords[] = {"buffer", NULL};

    struct file_object* self = (struct file_object*)_self;
    void*               buffer;
    Py_ssize_t          buffer_size;
    size_t              result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "y#", keywords, &buffer, &buffer_size)) {
        return NULL;
    }

    result = fwrite(buffer, 1, buffer_size, self->fp);
    return Py_BuildValue("k", (unsigned long)result);
}

static PyObject* _Nullable file_readline(PyObject* _self)
{
    struct file_object* self = (struct file_object*)_self;
    char                buffer[2048];
    char*               result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    result = fgets(buffer, 2048, self->fp);
    if (result == NULL) {
        return PyBytes_FromStringAndSize("", 0);
    } else {
        return PyBytes_FromString(result);
    }
}

static PyObject* _Nullable file_read(PyObject* _self, PyObject* args, PyObject* kwds)
{
    static char* keywords[] = {"size", NULL};

    struct file_object* self = (struct file_object*)_self;
    PyObject*           buffer;
    Py_ssize_t          buffer_size;
    size_t              result;

    if (self->fp == NULL) {
        PyErr_SetString(PyExc_ValueError, "Using closed file");
        return NULL;
    }

    if (!PyArg_ParseTupleAndKeywords(args, kwds, "n", keywords, &buffer_size)) {
        return NULL;
    }

    buffer = PyBytes_FromStringAndSize(NULL, buffer_size);
    if (buffer == NULL) {
        return NULL;
    }

    result = fread(PyBytes_AsString(buffer), 1, buffer_size, self->fp);

    _PyBytes_Resize(&buffer, result);
    return buffer;
}

static PyMethodDef file_methods[] = {{.ml_name  = "readline",
                                      .ml_meth  = (PyCFunction)file_readline,
                                      .ml_flags = METH_NOARGS,
                                      .ml_doc   = "read a line from the file"},
                                     {.ml_name  = "read",
                                      .ml_meth  = (PyCFunction)file_read,
                                      .ml_flags = METH_VARARGS | METH_KEYWORDS,
                                      .ml_doc   = "read from the file"},
                                     {.ml_name  = "write",
                                      .ml_meth  = (PyCFunction)file_write,
                                      .ml_flags = METH_VARARGS | METH_KEYWORDS,
                                      .ml_doc   = "write to the file"},
                                     {.ml_name  = "seek",
                                      .ml_meth  = (PyCFunction)file_seek,
                                      .ml_flags = METH_VARARGS | METH_KEYWORDS,
                                      .ml_doc   = "write to the file"},
                                     {
                                         .ml_name  = "has_errors",
                                         .ml_meth  = (PyCFunction)file_errors,
                                         .ml_flags = METH_NOARGS,
                                     },
                                     {
                                         .ml_name  = "at_eof",
                                         .ml_meth  = (PyCFunction)file_at_eof,
                                         .ml_flags = METH_NOARGS,
                                     },
                                     {.ml_name  = "tell",
                                      .ml_meth  = (PyCFunction)file_tell,
                                      .ml_flags = METH_NOARGS,
                                      .ml_doc   = "write to the file"},
                                     {.ml_name  = "fileno",
                                      .ml_meth  = (PyCFunction)file_fileno,
                                      .ml_flags = METH_NOARGS,
                                      .ml_doc   = "write to the file"},
                                     {.ml_name  = "flush",
                                      .ml_meth  = (PyCFunction)file_flush,
                                      .ml_flags = METH_NOARGS,
                                      .ml_doc   = "flush the file buffers"},
                                     {.ml_name  = "close",
                                      .ml_meth  = (PyCFunction)file_close,
                                      .ml_flags = METH_NOARGS,
                                      .ml_doc   = "close the file"},

                                     {.ml_name = NULL, /* Sentinel */}};

PyTypeObject FILE_Type = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0).tp_name = "objc.FILE",
    .tp_basicsize                                  = sizeof(struct file_object),
    .tp_itemsize                                   = 0,
    .tp_new                                        = file_new,
    .tp_dealloc                                    = file_dealloc,
    .tp_getattro                                   = PyObject_GenericGetAttr,
    .tp_flags                                      = Py_TPFLAGS_DEFAULT,
    .tp_doc                                        = "Wrapper around a FILE* object",
    .tp_methods                                    = file_methods,
};

PyObject*
FILE_create(FILE* fp)
{
    struct file_object* self;

    PyObjC_Assert(fp != NULL, NULL);

    self     = PyObject_NEW(struct file_object, &FILE_Type);
    self->fp = fp;
    return (PyObject*)self;
}

FILE* _Nullable FILE_get(PyObject* fp)
{
    if (!FILE_Check(fp)) {
        PyErr_Format(PyExc_TypeError, "Expecting objc.FILE, got %.100s",
                     Py_TYPE(fp)->tp_name);
        return NULL;
    }

    return ((struct file_object*)fp)->fp;
}

NS_ASSUME_NONNULL_END
