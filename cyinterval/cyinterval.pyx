from cpython.datetime cimport date
from datetime import date
from cpython cimport bool

cdef class BaseInterval:
    cdef readonly bool lower_closed
    cdef readonly bool upper_closed
    cdef readonly bool lower_bounded
    cdef readonly bool upper_bounded
        
    def __reduce__(BaseInterval self):
        return (self.__class__, self.init_args())
        
    def __hash__(BaseInterval self):
        return hash(self.__reduce__())
    
    def __nonzero__(BaseInterval self):
        return not self.empty()
    
    def __richcmp__(BaseInterval self, other, int op):
        if other.__class__ is self.__class__:
            return NotImplemented
        return self.richcmp(other, op)
        
    def __and__(BaseInterval self, other):
        if other.__class__ is self.__class__:
            raise NotImplementedError('Only intervals of the same type can be intersected')
        return self.intersection(other)
            



cdef class ObjectInterval(BaseInterval):
    cdef readonly object lower_bound
    cdef readonly object upper_bound
    def __init__(BaseInterval self, object lower_bound, object upper_bound, bool lower_closed, 
                 bool upper_closed, bool lower_bounded, bool upper_bounded):
        self.lower_closed = lower_closed
        self.upper_closed = upper_closed
        self.lower_bounded = lower_bounded
        self.upper_bouned = upper_bounded
        if lower_bounded:
            self.lower_bound = lower_bound
        if upper_bounded:
            self.upper_bound = upper_bounded
            
    cpdef tuple init_args(ObjectInterval self):
        return (self.lower_bound, self.upper_bound, self.lower_closed, self.upper_closed, 
                self.lower_bounded, self.upper_bounded)

    cpdef ObjectInterval intersection(ObjectInterval self, ObjectInterval other):
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef object new_lower_bound, new_upper_bound
        cdef bool new_lower_closed, new_lower_bounded, new_upper_closed, new_upper_bounded
        if lower_cmp <= 0:
            new_lower_bound = other.lower_bound
            new_lower_bounded = other.lower_bounded
            new_lower_closed = other.lower_closed
        else:
            new_lower_bound = self.lower_bound
            new_lower_bounded = self.lower_bounded
            new_lower_closed = self.lower_closed
        
        if upper_cmp <= 0:
            new_upper_bound = self.upper_bound
            new_upper_bounded = self.upper_bounded
            new_upper_closed = self.upper_closed
        else:
            new_upper_bound = other.upper_bound
            new_upper_bounded = other.upper_bounded
            new_upper_closed = other.upper_closed
        return ObjectInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
                
    cpdef empty(ObjectInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                (((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed or self.upper_closed))) or
                self.lower_bound > self.upper_bound))
    
    cpdef richcmp(ObjectInterval self, ObjectInterval other, int op):
        cdef int lower_cmp
        cdef int upper_cmp
        if op == 0 or op == 1:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return True
            elif lower_cmp == 1:
                return False
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return True
                elif upper_cmp == 1:
                    return False
                else: # upper_cmp == 0
                    return op == 1
        elif op == 2:
            return (self.lower_cmp(other) == 0) and (self.upper_cmp(other) == 0)
        elif op == 3:
            return (self.lower_cmp(other) != 0) or (self.upper_cmp(other) != 0)
        elif op == 4 or op == 5:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return False
            elif lower_cmp == 1:
                return True
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return False
                elif upper_cmp == 1:
                    return True
                else: # upper_cmp == 0
                    return op == 5
    
    cpdef int lower_cmp(ObjectInterval self, ObjectInterval other):
        if not self.lower_bounded:
            if not other.lower_bounded:
                return 0
            else:
                return -1
        elif other.lower_bounded:
            return 1
        if self.lower_bound < other.lower_bound:
            return -1
        elif self.lower_bound == other.lower_bound:
            if self.lower_closed and not other.lower_closed:
                return -1
            elif other.lower_closed and not self.lower_closed:
                return 1
            else:
                return 0
        else:
            return 1
    
    cpdef int upper_cmp(ObjectInterval self, ObjectInterval other):
        if not self.upper_bounded:
            if not other.upper_bounded:
                return 0
            else:
                return -1
        elif other.upper_bounded:
            return 1
        if self.upper_bound < other.upper_bound:
            return -1
        elif self.upper_bound == other.upper_bound:
            if self.upper_closed and not other.upper_closed:
                return 1
            elif other.upper_closed and not self.upper_closed:
                return -1
            else:
                return 0
        else:
            return 1

cdef class DateInterval(BaseInterval):
    cdef readonly date lower_bound
    cdef readonly date upper_bound
    def __init__(BaseInterval self, date lower_bound, date upper_bound, bool lower_closed, 
                 bool upper_closed, bool lower_bounded, bool upper_bounded):
        self.lower_closed = lower_closed
        self.upper_closed = upper_closed
        self.lower_bounded = lower_bounded
        self.upper_bouned = upper_bounded
        if lower_bounded:
            self.lower_bound = lower_bound
        if upper_bounded:
            self.upper_bound = upper_bounded
            
    cpdef tuple init_args(DateInterval self):
        return (self.lower_bound, self.upper_bound, self.lower_closed, self.upper_closed, 
                self.lower_bounded, self.upper_bounded)

    cpdef DateInterval intersection(DateInterval self, DateInterval other):
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef date new_lower_bound, new_upper_bound
        cdef bool new_lower_closed, new_lower_bounded, new_upper_closed, new_upper_bounded
        if lower_cmp <= 0:
            new_lower_bound = other.lower_bound
            new_lower_bounded = other.lower_bounded
            new_lower_closed = other.lower_closed
        else:
            new_lower_bound = self.lower_bound
            new_lower_bounded = self.lower_bounded
            new_lower_closed = self.lower_closed
        
        if upper_cmp <= 0:
            new_upper_bound = self.upper_bound
            new_upper_bounded = self.upper_bounded
            new_upper_closed = self.upper_closed
        else:
            new_upper_bound = other.upper_bound
            new_upper_bounded = other.upper_bounded
            new_upper_closed = other.upper_closed
        return DateInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
                
    cpdef empty(DateInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                (((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed or self.upper_closed))) or
                self.lower_bound > self.upper_bound))
    
    cpdef richcmp(DateInterval self, DateInterval other, int op):
        cdef int lower_cmp
        cdef int upper_cmp
        if op == 0 or op == 1:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return True
            elif lower_cmp == 1:
                return False
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return True
                elif upper_cmp == 1:
                    return False
                else: # upper_cmp == 0
                    return op == 1
        elif op == 2:
            return (self.lower_cmp(other) == 0) and (self.upper_cmp(other) == 0)
        elif op == 3:
            return (self.lower_cmp(other) != 0) or (self.upper_cmp(other) != 0)
        elif op == 4 or op == 5:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return False
            elif lower_cmp == 1:
                return True
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return False
                elif upper_cmp == 1:
                    return True
                else: # upper_cmp == 0
                    return op == 5
    
    cpdef int lower_cmp(DateInterval self, DateInterval other):
        if not self.lower_bounded:
            if not other.lower_bounded:
                return 0
            else:
                return -1
        elif other.lower_bounded:
            return 1
        if self.lower_bound < other.lower_bound:
            return -1
        elif self.lower_bound == other.lower_bound:
            if self.lower_closed and not other.lower_closed:
                return -1
            elif other.lower_closed and not self.lower_closed:
                return 1
            else:
                return 0
        else:
            return 1
    
    cpdef int upper_cmp(DateInterval self, DateInterval other):
        if not self.upper_bounded:
            if not other.upper_bounded:
                return 0
            else:
                return -1
        elif other.upper_bounded:
            return 1
        if self.upper_bound < other.upper_bound:
            return -1
        elif self.upper_bound == other.upper_bound:
            if self.upper_closed and not other.upper_closed:
                return 1
            elif other.upper_closed and not self.upper_closed:
                return -1
            else:
                return 0
        else:
            return 1

cdef class IntInterval(BaseInterval):
    cdef readonly int lower_bound
    cdef readonly int upper_bound
    def __init__(BaseInterval self, int lower_bound, int upper_bound, bool lower_closed, 
                 bool upper_closed, bool lower_bounded, bool upper_bounded):
        self.lower_closed = lower_closed
        self.upper_closed = upper_closed
        self.lower_bounded = lower_bounded
        self.upper_bouned = upper_bounded
        if lower_bounded:
            self.lower_bound = lower_bound
        if upper_bounded:
            self.upper_bound = upper_bounded
            
    cpdef tuple init_args(IntInterval self):
        return (self.lower_bound, self.upper_bound, self.lower_closed, self.upper_closed, 
                self.lower_bounded, self.upper_bounded)

    cpdef IntInterval intersection(IntInterval self, IntInterval other):
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef int new_lower_bound, new_upper_bound
        cdef bool new_lower_closed, new_lower_bounded, new_upper_closed, new_upper_bounded
        if lower_cmp <= 0:
            new_lower_bound = other.lower_bound
            new_lower_bounded = other.lower_bounded
            new_lower_closed = other.lower_closed
        else:
            new_lower_bound = self.lower_bound
            new_lower_bounded = self.lower_bounded
            new_lower_closed = self.lower_closed
        
        if upper_cmp <= 0:
            new_upper_bound = self.upper_bound
            new_upper_bounded = self.upper_bounded
            new_upper_closed = self.upper_closed
        else:
            new_upper_bound = other.upper_bound
            new_upper_bounded = other.upper_bounded
            new_upper_closed = other.upper_closed
        return IntInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
                
    cpdef empty(IntInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                (((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed or self.upper_closed))) or
                self.lower_bound > self.upper_bound))
    
    cpdef richcmp(IntInterval self, IntInterval other, int op):
        cdef int lower_cmp
        cdef int upper_cmp
        if op == 0 or op == 1:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return True
            elif lower_cmp == 1:
                return False
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return True
                elif upper_cmp == 1:
                    return False
                else: # upper_cmp == 0
                    return op == 1
        elif op == 2:
            return (self.lower_cmp(other) == 0) and (self.upper_cmp(other) == 0)
        elif op == 3:
            return (self.lower_cmp(other) != 0) or (self.upper_cmp(other) != 0)
        elif op == 4 or op == 5:
            lower_cmp = self.lower_cmp(other)
            if lower_cmp == -1:
                return False
            elif lower_cmp == 1:
                return True
            else: # lower_cmp == 0
                upper_cmp = self.upper_cmp(other)
                if upper_cmp == -1:
                    return False
                elif upper_cmp == 1:
                    return True
                else: # upper_cmp == 0
                    return op == 5
    
    cpdef int lower_cmp(IntInterval self, IntInterval other):
        if not self.lower_bounded:
            if not other.lower_bounded:
                return 0
            else:
                return -1
        elif other.lower_bounded:
            return 1
        if self.lower_bound < other.lower_bound:
            return -1
        elif self.lower_bound == other.lower_bound:
            if self.lower_closed and not other.lower_closed:
                return -1
            elif other.lower_closed and not self.lower_closed:
                return 1
            else:
                return 0
        else:
            return 1
    
    cpdef int upper_cmp(IntInterval self, IntInterval other):
        if not self.upper_bounded:
            if not other.upper_bounded:
                return 0
            else:
                return -1
        elif other.upper_bounded:
            return 1
        if self.upper_bound < other.upper_bound:
            return -1
        elif self.upper_bound == other.upper_bound:
            if self.upper_closed and not other.upper_closed:
                return 1
            elif other.upper_closed and not self.upper_closed:
                return -1
            else:
                return 0
        else:
            return 1


# This is just a singleton
class unbounded:
    def __init__(self):
        raise NotImplementedError('unbounded should not be instantiated')

interval_type_dispatch = {}
interval_default_value_dispatch = {}
interval_type_dispatch[date] = DateInterval
interval_default_value_dispatch[DateInterval] = None
interval_type_dispatch[int] = IntInterval
interval_default_value_dispatch[IntInterval] = 0
inverse_interval_type_dispatch = dict(zip(map(reversed, interval_type_dispatch.items())))
def Interval(lower_bound=unbounded, upper_bound=unbounded, lower_closed=True, 
             upper_closed=True, interval_type=None):
    if interval_type is None:
        assert lower_bound is not unbounded or upper_bound is not unbounded
        if lower_bound is not unbounded:
            cls = interval_type_dispatch[type(lower_bound)]
        else:
            cls = interval_type_dispatch[type(upper_bound)]
    elif interval_type in inverse_interval_type_dispatch:
        cls = interval_type
    elif interval_type in interval_type_dispatch:
        cls = interval_type_dispatch[interval_type]
    elif type(interval_type) in interval_type_dispatch:
        cls = interval_type_dispatch[type(interval_type)]
    else:
        cls = ObjectInterval
    default_value = interval_default_value_dispatch[cls]
    return cls(lower_bound if lower_bound is not unbounded else default_value,
               upper_bound if upper_bound is not unbounded else default_value,
               lower_closed, upper_closed, lower_bound is not unbounded, 
               upper_bound is not unbounded)
    
    
