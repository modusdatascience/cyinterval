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

cdef class BaseIntervalSetIterator:
    cdef unsigned int index

<%!
type_tups = [('ObjectInterval', 'object', None, 'None', False, 'ObjectIntervalSet'), 
              ('DateInterval', 'date', 'date', 'None', True, 'DateIntervalSet'),
              ('IntInterval', 'int', 'int', '0', True, 'IntIntervalSet'),
              ('FloatInterval', 'double', 'float', '0.', True, 'FloatIntervalSet')]
default_type_tup_index = 0
%>

% for IntervalType, c_type, p_type, default_value, dispatchable, IntervalSetType in type_tups:
cdef class ${IntervalType}(BaseInterval):
    cdef readonly ${c_type} lower_bound
    cdef readonly ${c_type} upper_bound
    cpdef bool adjacent(${IntervalType} self, ${c_type} lower, ${c_type} upper)
    cpdef int containment_cmp(${IntervalType} self, ${c_type} item)
    cpdef bool contains(${IntervalType} self, ${c_type} item)
    cpdef bool subset(${IntervalType} self, ${IntervalType} other)
    cpdef int overlap_cmp(${IntervalType} self, ${IntervalType} other)
    cpdef tuple init_args(${IntervalType} self)
    cpdef ${IntervalType} intersection(${IntervalType} self, ${IntervalType} other)
    cpdef ${IntervalType} fusion(${IntervalType} self, ${IntervalType} other)
    cpdef bool empty(${IntervalType} self)  
    cpdef bool richcmp(${IntervalType} self, ${IntervalType} other, int op)
    cpdef int lower_cmp(${IntervalType} self, ${IntervalType} other)
    cpdef int upper_cmp(${IntervalType} self, ${IntervalType} other)

cpdef tuple ${IntervalType}_preprocess_intervals(tuple intervals)

cdef class ${IntervalSetType}Iterator(BaseIntervalSetIterator):
    cdef readonly ${IntervalSetType} interval_set

cdef class ${IntervalSetType}(BaseIntervalSet):
    cpdef bool lower_bounded(${IntervalSetType} self)
    cpdef bool upper_bounded(${IntervalSetType} self)
    cpdef ${c_type} lower_bound(${IntervalSetType} self)
    cpdef ${c_type} upper_bound(${IntervalSetType} self)
    cpdef tuple init_args(${IntervalSetType} self)
    cpdef bool contains(${IntervalSetType} self, ${c_type} item)
    cpdef bool empty(${IntervalSetType} self)
    cpdef bool subset(${IntervalSetType} self, ${IntervalSetType} other)
    cpdef bool equal(${IntervalSetType} self, ${IntervalSetType} other)
    cpdef bool richcmp(${IntervalSetType} self, ${IntervalSetType} other, int op)
    cpdef ${IntervalSetType} intersection(${IntervalSetType} self, ${IntervalSetType} other)
    cpdef ${IntervalSetType} union(${IntervalSetType} self, ${IntervalSetType} other)
    cpdef ${IntervalSetType} complement(${IntervalSetType} self)
    cpdef ${IntervalSetType} minus(${IntervalSetType} self, ${IntervalSetType} other)

% endfor