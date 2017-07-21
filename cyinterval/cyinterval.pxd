from cpython.datetime cimport date, timedelta
from cpython cimport bool

cdef class BaseInterval:
    cdef readonly bool lower_closed
    cdef readonly bool upper_closed
    cdef readonly bool lower_bounded
    cdef readonly bool upper_bounded
    


cdef class ObjectInterval(BaseInterval):
    cdef readonly object lower_bound
    cdef readonly object upper_bound
    cpdef bool adjacent(ObjectInterval self, object lower, object upper)
    cpdef int containment_cmp(ObjectInterval self, object item)
    cpdef bool contains(ObjectInterval self, object item)
    cpdef int overlap_cmp(ObjectInterval self, ObjectInterval other)
    cpdef tuple init_args(ObjectInterval self)
    cpdef ObjectInterval intersection(ObjectInterval self, ObjectInterval other)
    cpdef ObjectInterval fusion(ObjectInterval self, ObjectInterval other)
    cpdef bool empty(ObjectInterval self)  
    cpdef int richcmp(ObjectInterval self, ObjectInterval other, int op)
    cpdef int lower_cmp(ObjectInterval self, ObjectInterval other)
    cpdef int upper_cmp(ObjectInterval self, ObjectInterval other)

cdef class DateInterval(BaseInterval):
    cdef readonly date lower_bound
    cdef readonly date upper_bound
    cpdef bool adjacent(DateInterval self, date lower, date upper)
    cpdef int containment_cmp(DateInterval self, date item)
    cpdef bool contains(DateInterval self, date item)
    cpdef int overlap_cmp(DateInterval self, DateInterval other)
    cpdef tuple init_args(DateInterval self)
    cpdef DateInterval intersection(DateInterval self, DateInterval other)
    cpdef DateInterval fusion(DateInterval self, DateInterval other)
    cpdef bool empty(DateInterval self)  
    cpdef int richcmp(DateInterval self, DateInterval other, int op)
    cpdef int lower_cmp(DateInterval self, DateInterval other)
    cpdef int upper_cmp(DateInterval self, DateInterval other)

cdef class IntInterval(BaseInterval):
    cdef readonly int lower_bound
    cdef readonly int upper_bound
    cpdef bool adjacent(IntInterval self, int lower, int upper)
    cpdef int containment_cmp(IntInterval self, int item)
    cpdef bool contains(IntInterval self, int item)
    cpdef int overlap_cmp(IntInterval self, IntInterval other)
    cpdef tuple init_args(IntInterval self)
    cpdef IntInterval intersection(IntInterval self, IntInterval other)
    cpdef IntInterval fusion(IntInterval self, IntInterval other)
    cpdef bool empty(IntInterval self)  
    cpdef int richcmp(IntInterval self, IntInterval other, int op)
    cpdef int lower_cmp(IntInterval self, IntInterval other)
    cpdef int upper_cmp(IntInterval self, IntInterval other)

cdef class FloatInterval(BaseInterval):
    cdef readonly double lower_bound
    cdef readonly double upper_bound
    cpdef bool adjacent(FloatInterval self, double lower, double upper)
    cpdef int containment_cmp(FloatInterval self, double item)
    cpdef bool contains(FloatInterval self, double item)
    cpdef int overlap_cmp(FloatInterval self, FloatInterval other)
    cpdef tuple init_args(FloatInterval self)
    cpdef FloatInterval intersection(FloatInterval self, FloatInterval other)
    cpdef FloatInterval fusion(FloatInterval self, FloatInterval other)
    cpdef bool empty(FloatInterval self)  
    cpdef int richcmp(FloatInterval self, FloatInterval other, int op)
    cpdef int lower_cmp(FloatInterval self, FloatInterval other)
    cpdef int upper_cmp(FloatInterval self, FloatInterval other)

