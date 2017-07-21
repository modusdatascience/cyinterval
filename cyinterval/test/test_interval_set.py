from cyinterval.cyinterval import Interval, IntervalSet
from nose.tools import assert_equal

def test_interval_set_construction():
    interval_set = IntervalSet(Interval(0.,1.), Interval(2.,3.))
    assert_equal(interval_set.intervals[0], Interval(0.,1.))
    assert_equal(interval_set.intervals[1], Interval(2.,3.))

if __name__ == '__main__':
    import sys
    import nose
    # This code will run the test in this file.'
    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s', '-v'])

