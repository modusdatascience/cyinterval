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
    
    def __contains__(BaseInterval self, item):
        return self.contains(item)

cdef class BaseIntervalSet:
    pass

cdef timedelta day = timedelta(days=1)


cdef class ObjectInterval(BaseInterval):
    def __init__(BaseInterval self, object lower_bound, object upper_bound, bool lower_closed, 
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
    cpdef bool adjacent(ObjectInterval self, object lower, object upper):
        return False
    
    cpdef int containment_cmp(ObjectInterval self, object item):
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
    
    cpdef bool contains(ObjectInterval self, object item):
        return self.containment_cmp(item) == 0
    
    cpdef int overlap_cmp(ObjectInterval self, ObjectInterval other):
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
    
    cpdef ObjectInterval fusion(ObjectInterval self, ObjectInterval other):
        '''
        Assume intervals overlap.  Return their union.  Results not correct
        for non-overlapping intervals
        '''
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef object new_lower_bound, new_upper_bound
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
        return ObjectInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef bool empty(ObjectInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                ((((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed and self.upper_closed))) or
                self.lower_bound > self.upper_bound) or 
                 (self.lower_bound < self.upper_bound and 
                  (not (self.lower_closed or self.upper_closed)) and
                  self.adjacent(self.lower_bound, self.upper_bound))))
    
    cpdef int richcmp(ObjectInterval self, ObjectInterval other, int op):
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
    
    cpdef int upper_cmp(ObjectInterval self, ObjectInterval other):
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

cdef class ObjectIntervalSet(BaseIntervalSet):
    cdef readonly tuple intervals
    cdef readonly int n_intervals
    def __init__(ObjectIntervalSet self, tuple intervals):
        '''
        The intervals must already be sorted and non-overlapping.
        '''
        self.intervals = intervals
        self.n_intervals = len(intervals)
        
    cpdef ObjectIntervalSet intersection(ObjectIntervalSet self, ObjectIntervalSet other):
        pass
    
    cpdef ObjectIntervalSet union(ObjectIntervalSet self, ObjectIntervalSet other):
        pass
    
    cpdef ObjectIntervalSet complement(ObjectIntervalSet self):
        pass
    
    cpdef ObjectIntervalSet minus(ObjectIntervalSet self, ObjectIntervalSet other):
        pass
    
    
    
    

cdef class DateInterval(BaseInterval):
    def __init__(BaseInterval self, date lower_bound, date upper_bound, bool lower_closed, 
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
    cpdef bool adjacent(DateInterval self, date lower, date upper):
        return lower + day == upper
    
    cpdef int containment_cmp(DateInterval self, date item):
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
    
    cpdef bool contains(DateInterval self, date item):
        return self.containment_cmp(item) == 0
    
    cpdef int overlap_cmp(DateInterval self, DateInterval other):
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
    
    cpdef DateInterval fusion(DateInterval self, DateInterval other):
        '''
        Assume intervals overlap.  Return their union.  Results not correct
        for non-overlapping intervals
        '''
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef date new_lower_bound, new_upper_bound
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
        return DateInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef bool empty(DateInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                ((((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed and self.upper_closed))) or
                self.lower_bound > self.upper_bound) or 
                 (self.lower_bound < self.upper_bound and 
                  (not (self.lower_closed or self.upper_closed)) and
                  self.adjacent(self.lower_bound, self.upper_bound))))
    
    cpdef int richcmp(DateInterval self, DateInterval other, int op):
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
    
    cpdef int upper_cmp(DateInterval self, DateInterval other):
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

cdef class DateIntervalSet(BaseIntervalSet):
    cdef readonly tuple intervals
    cdef readonly int n_intervals
    def __init__(DateIntervalSet self, tuple intervals):
        '''
        The intervals must already be sorted and non-overlapping.
        '''
        self.intervals = intervals
        self.n_intervals = len(intervals)
        
    cpdef DateIntervalSet intersection(DateIntervalSet self, DateIntervalSet other):
        pass
    
    cpdef DateIntervalSet union(DateIntervalSet self, DateIntervalSet other):
        pass
    
    cpdef DateIntervalSet complement(DateIntervalSet self):
        pass
    
    cpdef DateIntervalSet minus(DateIntervalSet self, DateIntervalSet other):
        pass
    
    
    
    

cdef class IntInterval(BaseInterval):
    def __init__(BaseInterval self, int lower_bound, int upper_bound, bool lower_closed, 
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
    cpdef bool adjacent(IntInterval self, int lower, int upper):
        return lower + 1 == upper
    
    cpdef int containment_cmp(IntInterval self, int item):
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
    
    cpdef bool contains(IntInterval self, int item):
        return self.containment_cmp(item) == 0
    
    cpdef int overlap_cmp(IntInterval self, IntInterval other):
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
    
    cpdef IntInterval fusion(IntInterval self, IntInterval other):
        '''
        Assume intervals overlap.  Return their union.  Results not correct
        for non-overlapping intervals
        '''
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef int new_lower_bound, new_upper_bound
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
        return IntInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef bool empty(IntInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                ((((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed and self.upper_closed))) or
                self.lower_bound > self.upper_bound) or 
                 (self.lower_bound < self.upper_bound and 
                  (not (self.lower_closed or self.upper_closed)) and
                  self.adjacent(self.lower_bound, self.upper_bound))))
    
    cpdef int richcmp(IntInterval self, IntInterval other, int op):
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
    
    cpdef int upper_cmp(IntInterval self, IntInterval other):
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

cdef class IntIntervalSet(BaseIntervalSet):
    cdef readonly tuple intervals
    cdef readonly int n_intervals
    def __init__(IntIntervalSet self, tuple intervals):
        '''
        The intervals must already be sorted and non-overlapping.
        '''
        self.intervals = intervals
        self.n_intervals = len(intervals)
        
    cpdef IntIntervalSet intersection(IntIntervalSet self, IntIntervalSet other):
        pass
    
    cpdef IntIntervalSet union(IntIntervalSet self, IntIntervalSet other):
        pass
    
    cpdef IntIntervalSet complement(IntIntervalSet self):
        pass
    
    cpdef IntIntervalSet minus(IntIntervalSet self, IntIntervalSet other):
        pass
    
    
    
    

cdef class FloatInterval(BaseInterval):
    def __init__(BaseInterval self, double lower_bound, double upper_bound, bool lower_closed, 
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
    cpdef bool adjacent(FloatInterval self, double lower, double upper):
        return False
    
    cpdef int containment_cmp(FloatInterval self, double item):
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
    
    cpdef bool contains(FloatInterval self, double item):
        return self.containment_cmp(item) == 0
    
    cpdef int overlap_cmp(FloatInterval self, FloatInterval other):
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
    
    cpdef tuple init_args(FloatInterval self):
        return (self.lower_bound, self.upper_bound, self.lower_closed, self.upper_closed, 
                self.lower_bounded, self.upper_bounded)

    cpdef FloatInterval intersection(FloatInterval self, FloatInterval other):
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef double new_lower_bound, new_upper_bound
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
        return FloatInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef FloatInterval fusion(FloatInterval self, FloatInterval other):
        '''
        Assume intervals overlap.  Return their union.  Results not correct
        for non-overlapping intervals
        '''
        cdef int lower_cmp = self.lower_cmp(other)
        cdef int upper_cmp = self.upper_cmp(other)
        cdef double new_lower_bound, new_upper_bound
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
        return FloatInterval(new_lower_bound, new_upper_bound, new_lower_closed, 
                               new_upper_closed, new_lower_bounded, new_upper_bounded)
    
    cpdef bool empty(FloatInterval self):
        return ((self.lower_bounded and self.upper_bounded) and 
                ((((self.lower_bound == self.upper_bound) and 
                (not (self.lower_closed and self.upper_closed))) or
                self.lower_bound > self.upper_bound) or 
                 (self.lower_bound < self.upper_bound and 
                  (not (self.lower_closed or self.upper_closed)) and
                  self.adjacent(self.lower_bound, self.upper_bound))))
    
    cpdef int richcmp(FloatInterval self, FloatInterval other, int op):
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
    
    cpdef int lower_cmp(FloatInterval self, FloatInterval other):
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
    
    cpdef int upper_cmp(FloatInterval self, FloatInterval other):
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

cdef class FloatIntervalSet(BaseIntervalSet):
    cdef readonly tuple intervals
    cdef readonly int n_intervals
    def __init__(FloatIntervalSet self, tuple intervals):
        '''
        The intervals must already be sorted and non-overlapping.
        '''
        self.intervals = intervals
        self.n_intervals = len(intervals)
        
    cpdef FloatIntervalSet intersection(FloatIntervalSet self, FloatIntervalSet other):
        pass
    
    cpdef FloatIntervalSet union(FloatIntervalSet self, FloatIntervalSet other):
        pass
    
    cpdef FloatIntervalSet complement(FloatIntervalSet self):
        pass
    
    cpdef FloatIntervalSet minus(FloatIntervalSet self, FloatIntervalSet other):
        pass
    
    
    
    


# This is just a singleton
class unbounded:
    def __init__(self):
        raise NotImplementedError('unbounded should not be instantiated')

interval_type_dispatch = {}
interval_default_value_dispatch = {}
interval_default_value_dispatch[ObjectInterval] = None
interval_type_dispatch[date] = DateInterval
interval_default_value_dispatch[DateInterval] = None
interval_type_dispatch[int] = IntInterval
interval_default_value_dispatch[IntInterval] = 0
interval_type_dispatch[float] = FloatInterval
interval_default_value_dispatch[FloatInterval] = 0.
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
            cls = ObjectInterval
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
    
    
