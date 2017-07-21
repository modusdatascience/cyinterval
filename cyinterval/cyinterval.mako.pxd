from cpython.datetime cimport date
from cpython cimport bool

cdef class BaseInterval:
    cdef readonly bool lower_closed
    cdef readonly bool upper_closed
    cdef readonly bool lower_bounded
    cdef readonly bool upper_bounded
    
<%!
type_tups = [('ObjectInterval', 'object', None, 'None', False), 
              ('DateInterval', 'date', 'date', 'None', True),
              ('IntInterval', 'int', 'int', '0', True),
              ('FloatInterval', 'double', 'float', '0.', True)]
default_type_tup_index = 0
%>

% for IntervalType, c_type, p_type, default_value, dispatchable in type_tups:
cdef class ${IntervalType}(BaseInterval):
    cdef readonly ${c_type} lower_bound
    cdef readonly ${c_type} upper_bound
    cpdef bool contains(${IntervalType} self, ${c_type} item)
    cpdef int overlap_cmp(${IntervalType} self, ${IntervalType} other)
    cpdef tuple init_args(${IntervalType} self)
    cpdef ${IntervalType} intersection(${IntervalType} self, ${IntervalType} other)  
    cpdef bool empty(${IntervalType} self)  
    cpdef int richcmp(${IntervalType} self, ${IntervalType} other, int op)
    cpdef int lower_cmp(${IntervalType} self, ${IntervalType} other)
    cpdef int upper_cmp(${IntervalType} self, ${IntervalType} other)

% endfor