from cpython.datetime cimport date, timedelta
from cpython cimport bool

cdef class BaseInterval:
    cdef readonly bool lower_closed
    cdef readonly bool upper_closed
    cdef readonly bool lower_bounded
    cdef readonly bool upper_bounded

cdef class BaseIntervalSet:
    cdef readonly tuple intervals
    cdef readonly int n_intervals



cdef class ObjectInterval(BaseInterval):
    cdef readonly object lower_bound
    cdef readonly object upper_bound
    cpdef bool adjacent(ObjectInterval self, object lower, object upper)
    cpdef int containment_cmp(ObjectInterval self, object item)
    cpdef bool contains(ObjectInterval self, object item)
    cpdef bool subset(ObjectInterval self, ObjectInterval other)
    cpdef int overlap_cmp(ObjectInterval self, ObjectInterval other)
    cpdef tuple init_args(ObjectInterval self)
    cpdef ObjectInterval intersection(ObjectInterval self, ObjectInterval other)
    cpdef ObjectInterval fusion(ObjectInterval self, ObjectInterval other)
    cpdef bool empty(ObjectInterval self)  
    cpdef bool richcmp(ObjectInterval self, ObjectInterval other, int op)
    cpdef int lower_cmp(ObjectInterval self, ObjectInterval other)
    cpdef int upper_cmp(ObjectInterval self, ObjectInterval other)

cpdef tuple ObjectInterval_preprocess_intervals(tuple intervals)

cdef class ObjectIntervalSet(BaseIntervalSet):
    cpdef tuple init_args(ObjectIntervalSet self)
    cpdef bool contains(ObjectIntervalSet self, object item)
    cpdef bool empty(ObjectIntervalSet self)
    cpdef bool subset(ObjectIntervalSet self, ObjectIntervalSet other)
    cpdef bool equal(ObjectIntervalSet self, ObjectIntervalSet other)
    cpdef bool richcmp(ObjectIntervalSet self, ObjectIntervalSet other, int op)
    cpdef ObjectIntervalSet intersection(ObjectIntervalSet self, ObjectIntervalSet other)
    cpdef ObjectIntervalSet union(ObjectIntervalSet self, ObjectIntervalSet other)
    cpdef ObjectIntervalSet complement(ObjectIntervalSet self)
    cpdef ObjectIntervalSet minus(ObjectIntervalSet self, ObjectIntervalSet other)

cdef class DateInterval(BaseInterval):
    cdef readonly date lower_bound
    cdef readonly date upper_bound
    cpdef bool adjacent(DateInterval self, date lower, date upper)
    cpdef int containment_cmp(DateInterval self, date item)
    cpdef bool contains(DateInterval self, date item)
    cpdef bool subset(DateInterval self, DateInterval other)
    cpdef int overlap_cmp(DateInterval self, DateInterval other)
    cpdef tuple init_args(DateInterval self)
    cpdef DateInterval intersection(DateInterval self, DateInterval other)
    cpdef DateInterval fusion(DateInterval self, DateInterval other)
    cpdef bool empty(DateInterval self)  
    cpdef bool richcmp(DateInterval self, DateInterval other, int op)
    cpdef int lower_cmp(DateInterval self, DateInterval other)
    cpdef int upper_cmp(DateInterval self, DateInterval other)

cpdef tuple DateInterval_preprocess_intervals(tuple intervals)

cdef class DateIntervalSet(BaseIntervalSet):
    cpdef tuple init_args(DateIntervalSet self)
    cpdef bool contains(DateIntervalSet self, date item)
    cpdef bool empty(DateIntervalSet self)
    cpdef bool subset(DateIntervalSet self, DateIntervalSet other)
    cpdef bool equal(DateIntervalSet self, DateIntervalSet other)
    cpdef bool richcmp(DateIntervalSet self, DateIntervalSet other, int op)
    cpdef DateIntervalSet intersection(DateIntervalSet self, DateIntervalSet other)
    cpdef DateIntervalSet union(DateIntervalSet self, DateIntervalSet other)
    cpdef DateIntervalSet complement(DateIntervalSet self)
    cpdef DateIntervalSet minus(DateIntervalSet self, DateIntervalSet other)

cdef class IntInterval(BaseInterval):
    cdef readonly int lower_bound
    cdef readonly int upper_bound
    cpdef bool adjacent(IntInterval self, int lower, int upper)
    cpdef int containment_cmp(IntInterval self, int item)
    cpdef bool contains(IntInterval self, int item)
    cpdef bool subset(IntInterval self, IntInterval other)
    cpdef int overlap_cmp(IntInterval self, IntInterval other)
    cpdef tuple init_args(IntInterval self)
    cpdef IntInterval intersection(IntInterval self, IntInterval other)
    cpdef IntInterval fusion(IntInterval self, IntInterval other)
    cpdef bool empty(IntInterval self)  
    cpdef bool richcmp(IntInterval self, IntInterval other, int op)
    cpdef int lower_cmp(IntInterval self, IntInterval other)
    cpdef int upper_cmp(IntInterval self, IntInterval other)

cpdef tuple IntInterval_preprocess_intervals(tuple intervals)

cdef class IntIntervalSet(BaseIntervalSet):
    cpdef tuple init_args(IntIntervalSet self)
    cpdef bool contains(IntIntervalSet self, int item)
    cpdef bool empty(IntIntervalSet self)
    cpdef bool subset(IntIntervalSet self, IntIntervalSet other)
    cpdef bool equal(IntIntervalSet self, IntIntervalSet other)
    cpdef bool richcmp(IntIntervalSet self, IntIntervalSet other, int op)
    cpdef IntIntervalSet intersection(IntIntervalSet self, IntIntervalSet other)
    cpdef IntIntervalSet union(IntIntervalSet self, IntIntervalSet other)
    cpdef IntIntervalSet complement(IntIntervalSet self)
    cpdef IntIntervalSet minus(IntIntervalSet self, IntIntervalSet other)

cdef class FloatInterval(BaseInterval):
    cdef readonly double lower_bound
    cdef readonly double upper_bound
    cpdef bool adjacent(FloatInterval self, double lower, double upper)
    cpdef int containment_cmp(FloatInterval self, double item)
    cpdef bool contains(FloatInterval self, double item)
    cpdef bool subset(FloatInterval self, FloatInterval other)
    cpdef int overlap_cmp(FloatInterval self, FloatInterval other)
    cpdef tuple init_args(FloatInterval self)
    cpdef FloatInterval intersection(FloatInterval self, FloatInterval other)
    cpdef FloatInterval fusion(FloatInterval self, FloatInterval other)
    cpdef bool empty(FloatInterval self)  
    cpdef bool richcmp(FloatInterval self, FloatInterval other, int op)
    cpdef int lower_cmp(FloatInterval self, FloatInterval other)
    cpdef int upper_cmp(FloatInterval self, FloatInterval other)

cpdef tuple FloatInterval_preprocess_intervals(tuple intervals)

cdef class FloatIntervalSet(BaseIntervalSet):
    cpdef tuple init_args(FloatIntervalSet self)
    cpdef bool contains(FloatIntervalSet self, double item)
    cpdef bool empty(FloatIntervalSet self)
    cpdef bool subset(FloatIntervalSet self, FloatIntervalSet other)
    cpdef bool equal(FloatIntervalSet self, FloatIntervalSet other)
    cpdef bool richcmp(FloatIntervalSet self, FloatIntervalSet other, int op)
    cpdef FloatIntervalSet intersection(FloatIntervalSet self, FloatIntervalSet other)
    cpdef FloatIntervalSet union(FloatIntervalSet self, FloatIntervalSet other)
    cpdef FloatIntervalSet complement(FloatIntervalSet self)
    cpdef FloatIntervalSet minus(FloatIntervalSet self, FloatIntervalSet other)

