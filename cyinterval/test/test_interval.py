from datetime import date
from cyinterval.cyinterval import Interval, DateInterval, IntInterval, FloatInterval, unbounded
from nose.tools import assert_equal
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

if __name__ == '__main__':
    import sys
    import nose
    # This code will run the test in this file.'
    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s', '-v'])