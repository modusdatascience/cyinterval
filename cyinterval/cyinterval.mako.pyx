from datetime import date

cdef class BaseInterval:
    '''
    Interpreted as the conjunction of two inequalities.
    '''
    def __reduce__(BaseInterval self):
        return (self.__class__, self.init_args())
        
    def __hash__(BaseInterval self):
        return hash(self.__reduce__())
    
    def __nonzero__(BaseInterval self):
        return not self.empty()
    
    def __richcmp__(BaseInterval self, other, int op):
        if other.__class__ is not self.__class__:
            return NotImplemented
        return self.richcmp(other, op)
        
    def __and__(BaseInterval self, other):
        if other.__class__ is self.__class__:
            raise NotImplementedError('Only intervals of the same type can be intersected')
        return self.intersection(other)
    
    def __rand__(BaseInterval self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return other.__and__(other)
    
    def __contains__(BaseInterval self, item):
        return self.contains(item)
    
    def __str__(BaseInterval self):
        return (('[' if self.lower_closed else '(') + (str(self.lower_bound) if self.lower_bounded else '-infty') + ',' + 
                (str(self.upper_bound) if self.upper_bounded else 'infty') + (']' if self.upper_closed else ')'))
    
    def __repr__(BaseInterval self):
        return str(self)
        
cdef class BaseIntervalSet:
    def __str__(BaseIntervalSet self):
        return 'U'.join(map(str, self.intervals)) if self.intervals else '{}'
    
    def __repr__(BaseIntervalSet self):
        return str(self)
    
    def __richcmp__(BaseIntervalSet self, other, int op):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return self.richcmp(other, op)
    
    def __and__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return self.intersection(other)
    
    def __or__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return self.union(other)
    
    def __ror__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return other.__or__(self)
    
    def __rand__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return other.__and__(other)
    
    def __sub__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return self.minus(other)
    
    def __rsub__(BaseIntervalSet self, other):
        if self.__class__ is not other.__class__:
            return NotImplemented
        return other.__sub__(self)
    
    def __invert__(BaseIntervalSet self):
        return self.complement()
    
    def __bool__(BaseIntervalSet self):
        return not self.empty()
    
    def __reduce__(BaseIntervalSet self):
        return (self.__class__, self.init_args())
    
    def __hash__(BaseIntervalSet self):
        return hash(self.__reduce__())
    
cdef timedelta day = timedelta(days=1)
<%!
type_tups = [('ObjectInterval', 'object', None, 'None', False, 'ObjectIntervalSet', False, None), 
              ('DateInterval', 'date', 'date', 'None', True, 'DateIntervalSet', True, 'day'),
              ('IntInterval', 'int', 'int', '0', True, 'IntIntervalSet', True, '1'),
              ('FloatInterval', 'double', 'float', '0.', True, 'FloatIntervalSet', False, None)]
default_type_tup_index = 0
%>

% for IntervalType, c_type, p_type, default_value, dispatchable, IntervalSetType, has_adjacent, unit in type_tups:
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
    
    # For some types, there is a concept of adjacent elements.  For example, 
    # there are no integers between 1 and 2 (although there are several real numbers).
    # If there is such a concept, it's possible for an interval to be empty even when 
    # the lower bound is strictly less than the upper bound, provided the bounds are strict 
    # (not closed).  The adjacent method is used to help determine such cases.
    % if has_adjacent:
    cpdef bool adjacent(${IntervalType} self, ${c_type} lower, ${c_type} upper):
        return lower + ${unit} == upper
    % else:
    cpdef bool adjacent(${IntervalType} self, ${c_type} lower, ${c_type} upper):
        return False
    % endif
    
    cpdef int containment_cmp(${IntervalType} self, ${c_type} item):
        if self.lower_bounded:
            if item < self.lower_bound:
                return -1
            elif item == self.lower_bound:
                if not self.lower_closed:
                    return -1
        # If we get here, the item satisfies the lower bound constraint
        if self.upper_bounded:
            if item > self.upper_bound:
                return 1
            elif item == self.upper_bound:
                if not self.upper_closed:
                    return 1
        # If we get here, the item also satisfies the upper bound constraint
        return 0
    
    cpdef bool contains(${IntervalType} self, ${c_type} item):
        return self.containment_cmp(item) == 0
    
    cpdef bool subset(${IntervalType} self, ${IntervalType} other):
        '''
        Return True if and only if self is a subset of other.
        '''
        cdef int lower_cmp, upper_cmp
        lower_cmp = self.lower_cmp(other)
        upper_cmp = self.upper_cmp(other)
        return lower_cmp >= 0 and upper_cmp <= 0
        
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
    
    cpdef ${IntervalType} fusion(${IntervalType} self, ${IntervalType} other):
        '''
        Assume union of intervals is a single interval.  Return their union.  Results not correct
        if above assumption is violated.
        '''
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef ${c_type} new_lower_bound, new_upper_bound
        cdef bool new_lower_closed, new_lower_bounded, new_upper_closed, new_upper_bounded
        if lower_cmp <= 0:
            new_lower_bound = self.lower_bound
            new_lower_bounded = self.lower_bounded
            new_lower_closed = self.lower_closed
        else:
            new_lower_bound = other.lower_bound
            new_lower_bounded = other.lower_bounded
            new_lower_closed = other.lower_closed
        
        if upper_cmp <= 0:
            new_upper_bound = other.upper_bound
            new_upper_bounded = other.upper_bounded
            new_upper_closed = other.upper_closed
        else:
            new_upper_bound = self.upper_bound
            new_upper_bounded = self.upper_bounded
            new_upper_closed = self.upper_closed
        return ${IntervalType}(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef bool empty(${IntervalType} self):
        return ((self.lower_bounded and self.upper_bounded) and 
                ((((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed and self.upper_closed))) or
                self.lower_bound > self.upper_bound) or 
                 (self.lower_bound < self.upper_bound and 
                  (not (self.lower_closed or self.upper_closed)) and
                  self.adjacent(self.lower_bound, self.upper_bound))))
    
    cpdef bool richcmp(${IntervalType} self, ${IntervalType} other, int op):
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
    
    cpdef int lower_cmp(${IntervalType} self, ${IntervalType} other):
        if not self.lower_bounded:
            if not other.lower_bounded:
                return 0
            else:
                return -1
        elif not other.lower_bounded:
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
                return 1
        elif not other.upper_bounded:
            return -1
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

# This is because static cpdef methods are not supported.  Otherwise this
# would be a static method of ${IntervalSetType}
cpdef tuple ${IntervalType}_preprocess_intervals(tuple intervals):
    # Remove any empty intervals
    cdef ${IntervalType} interval
    cdef list tmp = []
    for interval in intervals:
        if not interval.empty():
            tmp.append(interval)
            
    # Sort
    tmp.sort()
    
    # Fuse any overlapping intervals
    cdef list tmp2 = []
    cdef ${IntervalType} interval2
    cdef int overlap_cmp
    interval = tmp[0]
    for interval2 in tmp[1:]:
        overlap_cmp = interval.overlap_cmp(interval2)
        if (
            (overlap_cmp == 0) or 
            (overlap_cmp == -1 and interval.upper_bound == interval2.lower_bound and (interval.upper_closed or interval2.lower_closed)) or
            (overlap_cmp == 1 and interval2.upper_bound == interval.lower_bound and (interval2.upper_closed or interval.lower_closed))
            ):
            interval = interval.fusion(interval2)
        else:
            tmp2.append(interval)
            interval = interval2
    tmp2.append(interval)
    return tuple(tmp2)

cdef class ${IntervalSetType}(BaseIntervalSet):
    def __init__(${IntervalSetType} self, tuple intervals):
        '''
        The intervals must already be sorted and non-overlapping.
        '''
        self.intervals = intervals
        self.n_intervals = len(intervals)
        
    cpdef tuple init_args(${IntervalSetType} self):
        return (self.intervals,)
    
    cpdef bool subset(${IntervalSetType} self, ${IntervalSetType} other):
        '''
        Return True if and only if self is a subset of other.
        '''
        cdef ${IntervalType} self_interval, other_interval
        cdef int i, j, m, n
        cdef int overlap_cmp, cmp
        if self.empty():
            return True
        elif other.empty():
            return False
        m = self.n_intervals
        n = other.n_intervals
        j = 0
        other_interval = other.intervals[j]
        for i in range(m):
            self_interval = self.intervals[i]
            overlap_cmp = self_interval.overlap_cmp(other_interval)
            if overlap_cmp == -1:
                return False
            elif overlap_cmp == 0:
                if not self_interval.subset(other_interval):
                    return False
            elif overlap_cmp == 1:
                if j < n-1:
                    j += 1
                    other_interval = other.intervals[j]
                else:
                    return False
        return True
    
    cpdef bool equal(${IntervalSetType} self, ${IntervalSetType} other):
        cdef ${IntervalType} self_interval, other_interval
        cdef int i, n
        n = self.n_intervals
        if n != other.n_intervals:
            return False
        for i in range(n):
            self_interval = self.intervals[i]
            other_interval = other.intervals[i]
            if not self_interval.richcmp(other_interval, 2):
                return False
        return True
    
    cpdef bool richcmp(${IntervalSetType} self, ${IntervalSetType} other, int op):
        if op == 0:
            return self.subset(other) and not self.equal(other)
        elif op == 1:
            return self.subset(other)
        elif op == 2:
            return self.equal(other)
        elif op == 3:
            return not self.equal(other)
        elif op == 4:
            return other.subset(self) and not other.equal(self)
        elif op == 5:
            return other.subset(self)
    
    cpdef bool empty(${IntervalSetType} self):
        return self.n_intervals == 0 
    
    cpdef ${IntervalSetType} intersection(${IntervalSetType} self, ${IntervalSetType} other):
        if self.empty() or other.empty():
            return self
        cdef int i, j, m, n, cmp, upper_cmp
        i = 0
        j = 0
        m = self.n_intervals
        n = other.n_intervals
        cdef ${IntervalType} interval1, interval2
        interval1 = self.intervals[i]
        interval2 = other.intervals[j]
        cdef list new_intervals = []
        while True:
            cmp = interval1.overlap_cmp(interval2)
            if cmp == -1:
                i += 1
                if i <= m-1:
                    interval1 = self.intervals[i]
                else:
                    break
            elif cmp == 1:
                j += 1
                if j <= n-1:
                    interval2 = other.intervals[j]
                else:
                    break
            else:
                new_intervals.append(interval1.intersection(interval2))
                upper_cmp = interval1.upper_cmp(interval2)
                if upper_cmp <= 0:
                    i += 1
                    if i <= m-1:
                        interval1 = self.intervals[i]
                    else:
                        break
                if upper_cmp >= 0:
                    j += 1
                    if j <= n-1:
                        interval2 = other.intervals[j]
                    else:
                        break
        return ${IntervalSetType}(tuple(new_intervals))
    
    cpdef ${IntervalSetType} union(${IntervalSetType} self, ${IntervalSetType} other):
        cdef ${IntervalType} new_interval, interval1, interval2, next_interval
        if self.empty():
            return other
        if other.empty():
            return self
        interval1 = self.intervals[0]
        interval2 = other.intervals[0]
        
        cdef int i, j, m, n, cmp
        cdef bool richcmp, first = True
        i = 0
        j = 0
        m = self.n_intervals
        n = other.n_intervals
        cdef list new_intervals = []
        while i < m or j < n:
            if i == m:
                richcmp = False
            elif j == n:
                richcmp = True
            else:
                richcmp = interval1.richcmp(interval2, 1)
            if richcmp:
                next_interval = interval1 
                i += 1
                if i < m:
                    interval1 = self.intervals[i]
            else:
                next_interval = interval2
                j += 1
                if j < n:
                    interval2 = other.intervals[j]
            if first:
                first = False
                new_interval = next_interval
            else:
                cmp = new_interval.overlap_cmp(next_interval)
                if (cmp == 0 or 
                (cmp==-1 and new_interval.upper_bound == next_interval.lower_bound and 
                 (new_interval.upper_closed or next_interval.lower_closed)) or 
                 (cmp==1 and new_interval.lower_bound == next_interval.upper_bound and 
                 (new_interval.lower_closed or next_interval.upper_closed))):
                    new_interval = new_interval.fusion(next_interval)
                else:
                    new_intervals.append(new_interval)
                    new_interval = next_interval
        new_intervals.append(new_interval)
        return ${IntervalSetType}(tuple(new_intervals))
    
    cpdef ${IntervalSetType} complement(${IntervalSetType} self):
        if self.empty():
            return ${IntervalSetType}((${IntervalType}(${default_value}, ${default_value}, True, True, False, False),))
        cdef ${IntervalType} interval, previous
        cdef int i
        cdef n = self.n_intervals
        interval = self.intervals[0]
        cdef list new_intervals = []
        if interval.lower_bounded:
            new_intervals.append(${IntervalType}(${default_value}, interval.lower_bound, 
                                                 True, not interval.lower_closed, False, True))
        previous = interval
        for i in range(1,n):
            interval = self.intervals[i]
            new_intervals.append(${IntervalType}(previous.upper_bound, interval.lower_bound, not previous.upper_closed, 
                                                 not interval.lower_closed, True, True))
            previous = interval
        interval = self.intervals[n-1]
        if interval.upper_bounded:
            new_intervals.append(${IntervalType}(interval.upper_bound, ${default_value}, not interval.upper_closed, True, 
                                                 True, False))
        return ${IntervalSetType}(tuple(new_intervals))
            
    cpdef ${IntervalSetType} minus(${IntervalSetType} self, ${IntervalSetType} other):
        return self.intersection(other.complement())

% endfor

# This is just a singleton
class unbounded:
    def __init__(self):
        raise NotImplementedError('unbounded should not be instantiated')

cdef dict interval_type_dispatch = {}
cdef dict interval_default_value_dispatch = {}
cdef dict interval_set_type_dispatch = {}
cdef dict interval_set_preprocessor_dispatch = {}
% for IntervalType, c_type, p_type, default_value, dispatchable, IntervalSetType, has_adjacent, unit in type_tups:
% if dispatchable:
interval_type_dispatch[${p_type}] = ${IntervalType}
% endif
interval_default_value_dispatch[${IntervalType}] = ${default_value}
interval_set_type_dispatch[${IntervalType}] = ${IntervalSetType}
interval_set_preprocessor_dispatch[${IntervalType}] = ${IntervalType}_preprocess_intervals
% endfor
inverse_interval_type_dispatch = dict(map(tuple, map(reversed, interval_type_dispatch.items())))
def Interval(lower_bound=unbounded, upper_bound=unbounded, lower_closed=True, 
             upper_closed=True, interval_type=None):
    if interval_type is None:
        if lower_bound is not unbounded and type(lower_bound) in interval_type_dispatch:
            cls = interval_type_dispatch[type(lower_bound)]
        elif upper_bound is not unbounded and type(upper_bound) in interval_type_dispatch:
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

# Just a factory
def IntervalSet(*intervals, interval_type=None):
    if interval_type is None:
        if intervals:
            interval_cls = type(intervals[0])
            for interval in intervals[1:]:
                assert interval_cls is type(interval)
        else:
            interval_cls = ${type_tups[default_type_tup_index][0]}
    elif interval_type in inverse_interval_type_dispatch:
        interval_cls = interval_type
    elif interval_type in interval_type_dispatch:
        interval_cls = interval_type_dispatch[interval_type]
    elif type(interval_type) in interval_type_dispatch:
        interval_cls = interval_type_dispatch[type(interval_type)]
    else:
        interval_cls = ${type_tups[default_type_tup_index][0]}
    interval_set_type = interval_set_type_dispatch[interval_cls]
    interval_set_preprocessor = interval_set_preprocessor_dispatch[interval_cls]
    if intervals:
        processed_intervals = interval_set_preprocessor(intervals)
    else:
        processed_intervals = tuple()
    return interval_set_type(processed_intervals)


