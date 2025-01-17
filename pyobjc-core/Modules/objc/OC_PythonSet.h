NS_ASSUME_NONNULL_BEGIN

@interface OC_PythonSet : NSMutableSet {
    PyObject* value;
}

+ (instancetype _Nullable)setWithPythonObject:(PyObject*)value;
- (id _Nullable)initWithPythonObject:(PyObject*)value;
- (void)dealloc;
- (PyObject*)__pyobjc_PythonObject__;

@end

NS_ASSUME_NONNULL_END
