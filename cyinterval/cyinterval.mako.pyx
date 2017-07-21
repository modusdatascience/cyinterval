from datetime import date

cdef class BaseInterval:
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
    
    def __contains__(BaseInterval self, item):
        return self.contains(item)
            
<%!
type_tups = [('ObjectInterval', 'object', None, 'None', False), 
              ('DateInterval', 'date', 'date', 'None', True),
              ('IntInterval', 'int', 'int', '0', True),
              ('FloatInterval', 'double', 'float', '0.', True)]
default_type_tup_index = 0
%>

% for IntervalType, c_type, p_type, default_value, dispatchable in type_tups:
cdef class ${IntervalType}(BaseInterval):
    def __init__(BaseInterval self, ${c_type} lower_bound, ${c_type} upper_bound, bool lower_closed, 
                 bool upper_closed, bool lower_bounded, bool upper_bounded):
        self.lower_closed = lower_closed
        self.upper_closed = upper_closed
        self.lower_bounded = lower_bounded
        self.upper_bounded = upper_bounded
        if lower_bounded:
            self.lower_bound = lower_bound
        if upper_bounded:
            self.upper_bound = upper_bound
    
    cpdef bool contains(${IntervalType} self, ${c_type} item):
        if self.lower_closed and self.lower_bounded and item == self.lower_bound:
            return True
        if item > self.lower_bound and item < self.upper_bound:
            return True
        if not self.lower_bounded or item > self.lower_bound:
            if not self.upper_bounded or item < self.upper_bound:
                return True
        if self.upper_closed and self.upper_bounded and item == self.upper_bound:
            return True
        return False
    
#     cpdef int right_cmp(${IntervalType} self, ${IntervalType} other):
#         '''
#         Assume neither is empty.
#         Return -1 : self is always less than other
#         Return 0 : self is eventually in other on the right
#         Return 1 : self is eventually greater than other on the right
#         '''
#         if not self.upper_bounded and not other.upper_bounded:
#             return 0
#         elif self.upper_bounded:
#             if other.upper_bounded:
#                 if other.upper_bound > self.upper_bound:
#                     if other.lower_bounded:
#                         if self.upper_bound > other.lower_bound:
#                             return 0
#                         elif self.upper_bound == other.lower_bound:
#                             if self.upper_closed and other.lower_closed:
#                                 return 0
#                             else:
#                                 return -1
#                         else:
#                             return -1
#                     else:
#                         return 0
#                 elif other.upper_bound == self.upper_bound:
#                     if other.upper_closed or not self.upper_closed:
#                         return 0
#                     else:
#                         return 1
#                 else:
#                     return 1
#             else:
#                 if other.lower_bounded:
#                     if self.upper_bound > other.lower_bound:
#                         return 0
#                     elif self.upper_bound == other.lower_bound:
#                         if self.upper_closed and other.lower_closed:
#                             return 0
#                         else:
#                             return -1
#                     else:
#                         return -1
#         else:
#             return 1
#     
#     cpdef left_cmp(${IntervalType} self, ${IntervalType} other):
#         '''
#         Assume neither is empty.
#         Return -1 : self is eventually less than other on the left
#         Return 0 : self is eventually in other on the left
#         Return 1 : self is always greater than other
#         '''
#         if not self.lower_bounded and not other.lower_bounded:
#             return 0
#         elif self.lower_bounded:
#             if other.lower_bounded:
#                 if other.lower_bound > self.lower_bound:
#                     if other.upper_bounded:
#                         if self.lower_bound < other.upper_bound:
#                             return 0
#                         elif self.lower_bound == other.upper_bound:
#                             if self.lower_closed and other.upper_closed:
#                                 return 0
#                             else:
#                                 return 1
#                         else:
#                             return 1
#                     else:
#                         return 0
#                 elif other.lower_bound == self.lower_bound:
#                     if other.lower_closed or not self.lower_closed:
#                         return 0
#                     else:
#                         return -1
#                 else:
#                     return -1
#             else:
#                 if other.upper_bounded:
#                     if self.lower_bound < other.upper_bound:
#                         return 0
#                     elif self.lower_bound == other.upper_bound:
#                         if self.lower_closed and other.upper_closed:
#                             return 0
#                         else:
#                             return 1
#                     else:
#                         return 1
#         else:
#             return -1
        
    cpdef int overlap_cmp(${IntervalType} self, ${IntervalType} other):
        '''
        Assume both are nonempty.  Return -1 if every element of self is less than every 
        element of other.  Return 0 if self and other intersect.  Return 1 if every element of 
        self is greater than every element of other.
        '''
        cdef int lower_cmp, upper_cmp
        lower_cmp = self.lower_cmp(other)
        upper_cmp = self.upper_cmp(other)
        
        if self.upper_bounded and other.lower_bounded:
            if self.upper_bound < other.lower_bound:
                return -1
            elif self.upper_bound == other.lower_bound:
                if self.upper_closed and other.lower_closed:
                    return 0
                else:
                    return -1
        if self.lower_bounded and other.upper_bounded:
            if self.lower_bound > other.upper_bound:
                return 1
            elif self.lower_bound == other.upper_bound:
                if self.lower_closed and other.upper_closed:
                    return 0
                else:
                    return 1
        return 0
    
    cpdef tuple init_args(${IntervalType} self):
        return (self.lower_bound, self.upper_bound, self.lower_closed, self.upper_closed, 
                self.lower_bounded, self.upper_bounded)

    cpdef ${IntervalType} intersection(${IntervalType} self, ${IntervalType} other):
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef ${c_type} new_lower_bound, new_upper_bound
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
        return ${IntervalType}(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
                
    cpdef bool empty(${IntervalType} self):
        return ((self.lower_bounded and self.upper_bounded) and 
                (((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed or self.upper_closed))) or
                self.lower_bound > self.upper_bound))
    
    cpdef int richcmp(${IntervalType} self, ${IntervalType} other, int op):
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
    
#     cpdef int lower_upper_cmp(${IntervalType} self, ${IntervalType} other):
#         if not other.upper_bounded or not self.lower_bounded:
#             return -1
#         elif self.lower_bound < other.upper_bound:
#             return -1
#         elif self.lower_bound == other.upper_bound:
#             if self.
#             return 0
#         else:
#             return 1
#     
#     cpdef int upper_lower_cmp(${IntervalType} self, ${IntervalType} other):
#         '''
#         Is 
#         '''
#         return -1 * other.lower_upper_cmp(self)
    
    cpdef int lower_cmp(${IntervalType} self, ${IntervalType} other):
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
    
    cpdef int upper_cmp(${IntervalType} self, ${IntervalType} other):
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

% endfor

# This is just a singleton
class unbounded:
    def __init__(self):
        raise NotImplementedError('unbounded should not be instantiated')

interval_type_dispatch = {}
interval_default_value_dispatch = {}
% for IntervalType, c_type, p_type, default_value, dispatchable in type_tups:
% if dispatchable:
interval_type_dispatch[${p_type}] = ${IntervalType}
% endif
interval_default_value_dispatch[${IntervalType}] = ${default_value}
% endfor
inverse_interval_type_dispatch = dict(map(tuple, map(reversed, interval_type_dispatch.items())))
def Interval(lower_bound=unbounded, upper_bound=unbounded, lower_closed=True, 
             upper_closed=True, interval_type=None):
    if interval_type is None:
        assert lower_bound is not unbounded or upper_bound is not unbounded
        if lower_bound is not unbounded and type(lower_bound) in interval_type_dispatch:
            cls = interval_type_dispatch[type(lower_bound)]
        elif type(upper_bound) in interval_type_dispatch:
            cls = interval_type_dispatch[type(upper_bound)]
        else:
            cls = ${type_tups[default_type_tup_index][0]}
    elif interval_type in inverse_interval_type_dispatch:
        cls = interval_type
    elif interval_type in interval_type_dispatch:
        cls = interval_type_dispatch[interval_type]
    elif type(interval_type) in interval_type_dispatch:
        cls = interval_type_dispatch[type(interval_type)]
    else:
        cls = ${type_tups[default_type_tup_index][0]}
    default_value = interval_default_value_dispatch[cls]
    return cls(lower_bound if lower_bound is not unbounded else default_value,
               upper_bound if upper_bound is not unbounded else default_value,
               lower_closed, upper_closed, lower_bound is not unbounded, 
               upper_bound is not unbounded)
    
    
