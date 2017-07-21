from datetime import date
from cyinterval.cyinterval import Interval, DateInterval, IntInterval, FloatInterval, unbounded, ObjectInterval
from nose.tools import assert_equal, assert_in, assert_not_in

def test_date_interval_factory():
    interval = Interval(date(2012,1,1), date(2012,4,15))
    assert isinstance(interval, DateInterval)
    assert_equal(interval.lower_bound, date(2012,1,1))
    assert_equal(interval.upper_bound, date(2012,4,15))

def test_date_interval_factory_upper_unbounded():
    interval = Interval(date(2012,1,1))
    assert isinstance(interval, DateInterval)
    assert_equal(interval.lower_bound, date(2012,1,1))
    assert_equal(interval.upper_bounded, False)

def test_int_interval_factory():
    interval = Interval(5, 10, upper_closed=False)
    assert isinstance(interval, IntInterval)
    assert_equal(interval.lower_bound, 5)
    assert_equal(interval.upper_bound, 10)
    assert_equal(interval.upper_closed, False)

def test_float_interval_factory():
    interval = Interval(5., 10., upper_closed=False)
    assert isinstance(interval, FloatInterval)
    assert_equal(interval.lower_bound, 5.)
    assert_equal(interval.upper_bound, 10.)
    assert_equal(interval.upper_closed, False)

def test_object_inerval_factory():
    class HeavyFloat(object):
        def __init__(self, val):
            self.val = val
        def __lt__(self, other):
            return self.val < other.val
        def __eq__(self, other):
            return self.val == other.val
    
    one = HeavyFloat(1.)
    two = HeavyFloat(2.)
    interval = Interval(one, two)
    assert isinstance(interval, ObjectInterval)

def test_float_interval_contains():
    interval = Interval(5., 10., upper_closed=False)
    assert_in(5., interval)
    assert_in(5, interval)
    assert_not_in(10., interval)
    assert_in(9.9999, interval)
    assert_not_in(4.99999, interval)
    assert_in(6.5, interval)

def test_nonzero():
    interval1 = Interval(5., 10., upper_closed=False)
    interval2 = Interval(5., 5., lower_closed=False, upper_closed=False)
    interval3 = Interval(interval_type=float)
    assert bool(interval1)
    assert not bool(interval2)
    assert bool(interval3)


def test_object_interval_contains():
    class HeavyFloat(object):
        def __init__(self, val):
            self.val = val
        def __lt__(self, other):
            return self.val < other.val
        def __eq__(self, other):
            return self.val == other.val
    one = HeavyFloat(1.)
    two = HeavyFloat(2.)
    interval = Interval(one, two)
    assert_in(HeavyFloat(1.5), interval)
    assert_not_in(HeavyFloat(2.5), interval)

if __name__ == '__main__':
    import sys
    import nose
    # This code will run the test in this file.'
    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s', '-v'])