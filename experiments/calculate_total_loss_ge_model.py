import sys

# arguments: p, r, 1 - h, 1 - k

def calc(p, r, one_minus_h, one_minus_k):
    h = 1 - one_minus_h
    k = 1 - one_minus_k
    return (p * (1 - h) + r * (1 - k)) / (p + r)

print(calc(float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])))
