from datetime import date
from cyinterval.cyinterval import Interval, DateInterval, IntInterval, FloatInterval, unbounded, ObjectInterval
from nose.tools import assert_equal, assert_in, assert_not_in, assert_raises,\
    assert_false, assert_true

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

def test_interval_type_argument():
    interval = Interval(interval_type=1.)
    assert isinstance(interval, FloatInterval)
    interval = Interval(interval_type=float)
    assert isinstance(interval, FloatInterval)
    interval = Interval(interval_type=FloatInterval)
    assert isinstance(interval, FloatInterval)
    assert_raises(TypeError, lambda: Interval(lower_bound=date(2012,1,1), interval_type=FloatInterval))

def test_overlap_cmp():
    interval1 = Interval(0.,1.)
    interval2 = Interval(-1.,0.,upper_closed=False)
    assert_equal(interval2.overlap_cmp(interval1), -1)
    assert_equal(interval1.overlap_cmp(interval2), 1)
    interval3 = Interval(-1.,0.)
    assert_equal(interval3.overlap_cmp(interval1), 0)
    assert_equal(interval1.overlap_cmp(interval3), 0)
    assert_equal(interval3.overlap_cmp(interval2), 0)
    assert_equal(interval2.overlap_cmp(interval3), 0)
    interval4 = Interval(.5,.6)
    assert_equal(interval4.overlap_cmp(interval1), 0)
    assert_equal(interval1.overlap_cmp(interval4), 0)
    interval5 = Interval(5.5,22.)
    assert_equal(interval5.overlap_cmp(interval1), 1)
    assert_equal(interval1.overlap_cmp(interval5), -1)

def test_empty():
    interval = Interval(1., 1.1)
    assert_false(interval.empty())
    interval = Interval(1., 1.1, lower_closed=False)
    assert_false(interval.empty())
    interval = Interval(1., 1.1, lower_closed=False, upper_closed=False)
    assert_false(interval.empty())
    interval = Interval(1., 1.)
    assert_false(interval.empty())
    interval = Interval(1., 1., lower_closed=False)
    assert_true(interval.empty())
    interval = Interval(1., 1., upper_closed=False)
    assert_true(interval.empty())
    interval = Interval(1., 1., lower_closed=False, upper_closed=False)
    assert_true(interval.empty())
    interval = Interval(1.0000001, 1.)
    assert_true(interval.empty())
    
    # There are no integers between 1 and 2
    interval = Interval(1,2,lower_closed=False, upper_closed=False)
    assert_true(interval.empty())
    interval = Interval(1,2,lower_closed=False, upper_closed=True)
    assert_false(interval.empty())
    interval = Interval(1,2,lower_closed=True, upper_closed=False)
    assert_false(interval.empty())
    
    # There are no days between December 31 and January 1 of consecutive years
    interval = Interval(date(2011,12,31), date(2012,1,1), lower_closed=False, upper_closed=False)
    assert_true(interval.empty())
    interval = Interval(date(2011,12,31), date(2012,1,1), lower_closed=False, upper_closed=True)
    assert_false(interval.empty())
    interval = Interval(date(2011,12,31), date(2012,1,1), lower_closed=True, upper_closed=False)
    assert_false(interval.empty())
    # Happy New Year!

def test_lower_cmp():
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 4.)
    assert_equal(interval1.lower_cmp(interval2), 0)
    interval1 = Interval(unbounded,2.)
    interval2 = Interval(1., 4.)
    assert_equal(interval1.lower_cmp(interval2), -1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(unbounded, 4.)
    assert_equal(interval1.lower_cmp(interval2), 1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(0., 4.)
    assert_equal(interval1.lower_cmp(interval2), 1)
    interval1 = Interval(0.,2.)
    interval2 = Interval(1., 4.)
    assert_equal(interval1.lower_cmp(interval2), -1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 4.,lower_closed=False)
    assert_equal(interval1.lower_cmp(interval2), -1)
    interval1 = Interval(1.,2.,lower_closed=False)
    interval2 = Interval(1., 4.)
    assert_equal(interval1.lower_cmp(interval2), 1)

def test_upper_cmp():
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 2.)
    assert_equal(interval1.upper_cmp(interval2), 0)
    interval1 = Interval(1.,unbounded)
    interval2 = Interval(1.,2.)
    assert_equal(interval1.upper_cmp(interval2), 1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., unbounded)
    assert_equal(interval1.upper_cmp(interval2), -1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 1.5)
    assert_equal(interval1.upper_cmp(interval2), 1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 4.)
    assert_equal(interval1.upper_cmp(interval2), -1)
    interval1 = Interval(1.,2.)
    interval2 = Interval(1., 2.,upper_closed=False)
    assert_equal(interval1.upper_cmp(interval2), 1)
    interval1 = Interval(1.,2.,upper_closed=False)
    interval2 = Interval(1., 2.)
    assert_equal(interval1.upper_cmp(interval2), -1)

def test_fusion():
    interval1 = Interval(1.,2.)
    interval2 = Interval(2.,3., upper_closed=False)
    fused = interval1.fusion(interval2)
    assert_equal(fused.lower_bound, 1.)
    assert_equal(fused.lower_closed, True)
    assert_equal(fused.lower_bounded, True)
    assert_equal(fused.upper_bound, 3.)
    assert_equal(fused.upper_closed, False)
    assert_equal(fused.upper_bounded, True)
    interval1 = Interval(1.,2.)
    interval2 = Interval(unbounded, 3. , upper_closed=False)
    fused = interval1.fusion(interval2)
    assert_equal(interval2, fused)
    
def test_richcmp():
    interval1 = Interval(1.,2.)
    interval2 = Interval(2.,3.)
    assert_true(interval1.richcmp(interval2, 0))
    assert_false(interval2.richcmp(interval1, 0))
    assert_true(interval1.richcmp(interval2, 1))
    assert_false(interval2.richcmp(interval1, 1))
    assert_false(interval1.richcmp(interval2, 2))
    assert_false(interval2.richcmp(interval1, 2))
    assert_true(interval1.richcmp(interval2, 3))
    assert_true(interval2.richcmp(interval1, 3))
    assert_false(interval1.richcmp(interval2, 4))
    assert_true(interval2.richcmp(interval1, 4))
    assert_false(interval1.richcmp(interval2, 5))
    assert_true(interval2.richcmp(interval1, 5))
    
    
if __name__ == '__main__':
    import sys
    import nose
    # This code will run the test in this file.'
    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s', '-v'])