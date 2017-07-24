from cyinterval.cyinterval import Interval, IntervalSet, FloatIntervalSet, DateIntervalSet,\
    unbounded, ObjectIntervalSet
from nose.tools import assert_equal, assert_is, assert_not_equal, assert_less,\
    assert_less_equal, assert_greater_equal, assert_in, assert_not_in,\
    assert_raises
from datetime import date

def test_float_interval_set_construction():
    interval_set = IntervalSet(Interval(0.,1.), Interval(2.,3.))
    assert_equal(len(interval_set.intervals), 2)
    assert_equal(interval_set.intervals[0], Interval(0.,1.))
    assert_equal(interval_set.intervals[1], Interval(2.,3.))
    assert_is(type(interval_set), FloatIntervalSet)
 
def test_date_interval_set_construction():
    interval_set = IntervalSet(Interval(date(2012,1,1),date(2012,2,5)), Interval(date(2014,12,3),date(2015,3,17)))
    assert_equal(len(interval_set.intervals), 2)
    assert_equal(interval_set.intervals[0], Interval(date(2012,1,1),date(2012,2,5)))
    assert_equal(interval_set.intervals[1], Interval(date(2014,12,3),date(2015,3,17)))
    assert_is(type(interval_set), DateIntervalSet)
 
def test_interval_set_construction_single_interval():
    interval_set = IntervalSet(Interval(0.,1.))
    assert_equal(len(interval_set.intervals), 1)
    assert_equal(interval_set.intervals[0], Interval(0.,1.))
    assert_is(type(interval_set), FloatIntervalSet)

def test_interval_set_construction_fusion():
    interval_set = IntervalSet(Interval(0.,1.), Interval(1.,3.))
    assert_equal(interval_set.intervals[0], Interval(0.,3.))
    assert_equal(len(interval_set.intervals), 1)
    assert_is(type(interval_set), FloatIntervalSet)
     
    interval_set = IntervalSet(Interval(1.,3.), Interval(0.,1.))
    assert_equal(interval_set.intervals[0], Interval(0.,3.))
    assert_equal(len(interval_set.intervals), 1)
    assert_is(type(interval_set), FloatIntervalSet)
     
    interval_set = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    assert_equal(interval_set.intervals[0], Interval(0.,1.,upper_closed=False))
    assert_equal(interval_set.intervals[1], Interval(1.,3.,lower_closed=False))
    assert_equal(len(interval_set.intervals), 2)
    assert_is(type(interval_set), FloatIntervalSet)
    
    interval_set = IntervalSet(Interval(1.,3.,lower_closed=False), Interval(1.,1.), Interval(0.,1.,upper_closed=False))
    assert_equal(interval_set.intervals[0], Interval(0.,3.), str(interval_set.intervals[0]))
    assert_equal(len(interval_set.intervals), 1)
    assert_is(type(interval_set), FloatIntervalSet)
    
    interval_set = IntervalSet(Interval(0.,1.000001,upper_closed=False), Interval(1.,3.,lower_closed=False))
    assert_equal(interval_set.intervals[0], Interval(0.,3.))
    assert_equal(len(interval_set.intervals), 1)
    assert_is(type(interval_set), FloatIntervalSet)
    
def test_intersection():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    interval_set2 = IntervalSet(Interval(.5,1.5))
    assert_equal(interval_set1.intersection(interval_set2).intervals,
                 IntervalSet(Interval(.5,1.,upper_closed=False), Interval(1.,1.5,lower_closed=False)).intervals)
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False))
    interval_set2 = IntervalSet(Interval(1.,3.,lower_closed=False))
    assert_equal(interval_set1.intersection(interval_set2).intervals,
                 tuple())
    
def test_union():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    interval_set2 = IntervalSet(Interval(.5,1.5))
    assert_equal(interval_set1.union(interval_set2).intervals, (Interval(0., 3.),))
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False))
    interval_set2 = IntervalSet(Interval(1.,3.,lower_closed=False))
    assert_equal(interval_set1.union(interval_set2).intervals, (Interval(0., 1., upper_closed=False), 
                                                                Interval(1.,3.,lower_closed=False)))

def test_complement():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    assert_equal(interval_set1.complement().intervals, (Interval(unbounded, 0., upper_closed=False), 
                                                        Interval(1.,1.), Interval(3.,unbounded, lower_closed=False)))
    assert_equal(IntervalSet(interval_type=float).complement().intervals, 
                 IntervalSet(Interval(unbounded, unbounded, interval_type=float)).intervals)
    assert_equal(interval_set1.complement().complement(),
                 interval_set1)
    

def test_minus():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    interval_set2 = IntervalSet(Interval(.5,1.5))
    assert_equal(interval_set1.minus(interval_set2).intervals, (Interval(0.,.5,upper_closed=False), 
                                                                Interval(1.5,3., lower_closed=False)))
    assert_equal(interval_set2.minus(interval_set1).intervals,
                 (Interval(1.,1.),))

def test_operators():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    interval_set2 = IntervalSet(Interval(.5,1.5))
    assert_not_equal(interval_set1, interval_set2)
    assert_less_equal(interval_set1, interval_set1)
    assert_greater_equal(interval_set1, interval_set1)
    assert_equal(interval_set2, IntervalSet(Interval(.5,1.5)))
    assert_less(interval_set1 & interval_set2, interval_set2)
    assert_less(interval_set1 & interval_set2, interval_set1)
    assert_less(interval_set1, interval_set1 | interval_set2)
    assert_less(interval_set2, interval_set1 | interval_set2)
    assert_equal(~~interval_set2, interval_set2)
    assert_equal((~interval_set2) & interval_set2, IntervalSet(interval_type=float))
    assert_equal((~interval_set2) | interval_set2, IntervalSet(Interval(unbounded, unbounded, interval_type=float)))
    assert_equal(interval_set1 - interval_set2, IntervalSet(Interval(0.,.5,upper_closed=False), Interval(1.5,3.,lower_closed=False)))

def test_default_type():
    interval_set = IntervalSet(Interval(unbounded, unbounded))
    assert_is(type(interval_set), ObjectIntervalSet)
    interval_set = IntervalSet()
    assert_is(type(interval_set), ObjectIntervalSet)
    
def test_contains():
    interval_set1 = IntervalSet(Interval(0.,1.,upper_closed=False), Interval(1.,3.,lower_closed=False))
    assert_in(.3, interval_set1)
    assert_not_in(1., interval_set1)
    assert_not_in(-0.00001, interval_set1)
    assert_not_in(3.000001, interval_set1)
    assert_in(2., interval_set1)
    assert_in(2, interval_set1) # int automatically cast as double
    assert_raises(TypeError, lambda: 'x' in interval_set1)

if __name__ == '__main__':
    import sys
    import nose
    # This code will run the test in this file.'
    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s', '-v'])

