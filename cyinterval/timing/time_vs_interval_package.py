from interval import Interval as OrigInterval, IntervalSet as OrigIntervalSet
from cyinterval.cyinterval import Interval as CyInterval, IntervalSet as CyIntervalSet
import time
def compare_intersection():
    cyinterval_set1 = CyIntervalSet(CyInterval(0.,1.,upper_closed=False), CyInterval(1.,3.,lower_closed=False))
    cyinterval_set2 = CyIntervalSet(CyInterval(.5,1.5))
    orinterval_set1 = OrigIntervalSet([CyInterval(0.,1.,upper_closed=False), OrigInterval(1.,3.,lower_closed=False)])
    orinterval_set2 = OrigIntervalSet([OrigInterval(.5,1.5)])
    n = 100000
    t0 = time.time()
    for _ in range(n):
        cyinterval_set1.intersection(cyinterval_set2)
    t1 = time.time()
    print 'cyinterval took %f seconds for %d iterations' % (t1-t0, n)
    d_cy = t1-t0
    t0 = time.time()
    for _ in range(n):
        orinterval_set1.intersection(orinterval_set2)
    t1 = time.time()
    d_orig = t1 - t0
    print 'interval took %f seconds for %d iterations' % (t1-t0, n)
    print 'cyinterval was %f times as fast as interval' % (d_orig / d_cy)
    
    
if __name__ == '__main__':
    compare_intersection()