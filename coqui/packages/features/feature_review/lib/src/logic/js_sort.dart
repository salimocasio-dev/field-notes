/// `Array.prototype.sort` as V8 runs it (Node 22 and Chrome): TimSort, with the same calls of the comparison
/// function in the same order.
///
/// The old pages shuffle with `list.sort(() => Math.random() - .5)` (cual.js `cualLista`, nivel.js `nivelItem`).
/// That comparison is not consistent, so what comes out, and how many random numbers it eats, depends on the
/// sorting algorithm itself. To make a seeded session the same session, the algorithm is ported too: V8's
/// `third_party/v8/builtins/array-sort.tq` (a port of CPython's listsort), call for call. Dart's own `List.sort`
/// is a different algorithm and would draw differently.
///
/// [jsSort] sorts [items] in place. [compare] is called as V8 calls the comparison function: a negative result
/// means "the first is before the second". Checked against Node by `test/js_sort_test.dart`.
library;

void jsSort<T>(List<T> items, num Function(T a, T b) compare) {
  _TimSort<T>(items, compare).sort();
}

class _Run {
  _Run(this.base, this.length);
  int base;
  int length;
}

class _TimSort<T> {
  _TimSort(this.work, this.cmp);

  // array-sort.tq: kMinGallopWins
  static const int _minGallopWins = 7;

  final List<T> work;
  final num Function(T a, T b) cmp;
  int minGallop = _minGallopWins;
  final List<_Run> runs = [];

  num _compare(T a, T b) {
    final v = cmp(a, b);
    return v.isNaN ? 0 : v;
  }

  // array-sort.tq: ArrayTimSortImpl
  void sort() {
    final length = work.length;
    if (length < 2) return;
    var low = 0;
    var remaining = length;
    final minRunLength = _computeMinRunLength(remaining);
    while (remaining != 0) {
      var currentRunLength = _countAndMakeRun(low, low + remaining);
      if (currentRunLength < minRunLength) {
        final forced = remaining < minRunLength ? remaining : minRunLength;
        _binaryInsertionSort(low, low + currentRunLength, low + forced);
        currentRunLength = forced;
      }
      runs.add(_Run(low, currentRunLength));
      _mergeCollapse();
      low += currentRunLength;
      remaining -= currentRunLength;
    }
    _mergeForceCollapse();
  }

  // array-sort.tq: ComputeMinRunLength
  static int _computeMinRunLength(int nArg) {
    var n = nArg;
    var r = 0;
    while (n >= 64) {
      r |= n & 1;
      n >>= 1;
    }
    return n + r;
  }

  // array-sort.tq: CountAndMakeRun
  int _countAndMakeRun(int lowArg, int high) {
    final low = lowArg + 1;
    if (low == high) return 1;
    var runLength = 2;
    final elementLow = work[low];
    final elementHigh = work[low - 1];
    var order = _compare(elementLow, elementHigh);
    final isDescending = order < 0;
    var previous = elementLow;
    for (var idx = low + 1; idx < high; ++idx) {
      final current = work[idx];
      order = _compare(current, previous);
      if (isDescending) {
        if (order >= 0) break;
      } else {
        if (order < 0) break;
      }
      previous = current;
      ++runLength;
    }
    if (isDescending) _reverseRange(lowArg, lowArg + runLength);
    return runLength;
  }

  void _reverseRange(int from, int to) {
    var low = from;
    var high = to - 1;
    while (low < high) {
      final t = work[low];
      work[low] = work[high];
      work[high] = t;
      ++low;
      --high;
    }
  }

  // array-sort.tq: BinaryInsertionSort
  void _binaryInsertionSort(int low, int startArg, int high) {
    var start = low == startArg ? startArg + 1 : startArg;
    for (; start < high; ++start) {
      var left = low;
      var right = start;
      final pivot = work[right];
      while (left < right) {
        final mid = left + ((right - left) >> 1);
        final order = _compare(pivot, work[mid]);
        if (order < 0) {
          right = mid;
        } else {
          left = mid + 1;
        }
      }
      for (var p = start; p > left; --p) {
        work[p] = work[p - 1];
      }
      work[left] = pivot;
    }
  }

  // array-sort.tq: RunInvariantEstablished
  bool _runInvariantEstablished(int n) {
    if (n < 2) return true;
    final runLengthN = runs[n].length;
    final runLengthNM = runs[n - 1].length;
    final runLengthNMM = runs[n - 2].length;
    return runLengthNMM > runLengthNM + runLengthN;
  }

  // array-sort.tq: MergeCollapse
  void _mergeCollapse() {
    while (runs.length > 1) {
      var n = runs.length - 2;
      if (!_runInvariantEstablished(n + 1) || !_runInvariantEstablished(n)) {
        if (runs[n - 1].length < runs[n + 1].length) {
          --n;
        }
        _mergeAt(n);
      } else if (runs[n].length <= runs[n + 1].length) {
        _mergeAt(n);
      } else {
        break;
      }
    }
  }

  // array-sort.tq: MergeForceCollapse
  void _mergeForceCollapse() {
    while (runs.length > 1) {
      var n = runs.length - 2;
      if (n > 0 && runs[n - 1].length < runs[n + 1].length) {
        --n;
      }
      _mergeAt(n);
    }
  }

  // array-sort.tq: MergeAt
  void _mergeAt(int i) {
    final stackSize = runs.length;
    var baseA = runs[i].base;
    var lengthA = runs[i].length;
    final baseB = runs[i + 1].base;
    var lengthB = runs[i + 1].length;

    runs[i].length = lengthA + lengthB;
    if (i == stackSize - 3) {
      runs[i + 1].base = runs[i + 2].base;
      runs[i + 1].length = runs[i + 2].length;
    }
    runs.removeLast();

    final keyRight = work[baseB];
    final k = _gallopRight(work, keyRight, baseA, lengthA, 0);
    baseA += k;
    lengthA -= k;
    if (lengthA == 0) return;

    final keyLeft = work[baseA + lengthA - 1];
    lengthB = _gallopLeft(work, keyLeft, baseB, lengthB, lengthB - 1);
    if (lengthB == 0) return;

    if (lengthA <= lengthB) {
      _mergeLow(baseA, lengthA, baseB, lengthB);
    } else {
      _mergeHigh(baseA, lengthA, baseB, lengthB);
    }
  }

  // array-sort.tq: GallopLeft
  int _gallopLeft(List<T> array, T key, int base, int length, int hint) {
    var lastOfs = 0;
    var offset = 1;
    final baseHintElement = array[base + hint];
    var order = _compare(baseHintElement, key);
    if (order < 0) {
      final maxOfs = length - hint;
      while (offset < maxOfs) {
        final offsetElement = array[base + hint + offset];
        order = _compare(offsetElement, key);
        if (order >= 0) break;
        lastOfs = offset;
        offset = (offset << 1) + 1;
        if (offset <= 0) offset = maxOfs;
      }
      if (offset > maxOfs) offset = maxOfs;
      lastOfs += hint;
      offset += hint;
    } else {
      final maxOfs = hint + 1;
      while (offset < maxOfs) {
        final offsetElement = array[base + hint - offset];
        order = _compare(offsetElement, key);
        if (order < 0) break;
        lastOfs = offset;
        offset = (offset << 1) + 1;
        if (offset <= 0) offset = maxOfs;
      }
      if (offset > maxOfs) offset = maxOfs;
      final tmp = lastOfs;
      lastOfs = hint - offset;
      offset = hint - tmp;
    }
    lastOfs++;
    while (lastOfs < offset) {
      final m = lastOfs + ((offset - lastOfs) >> 1);
      order = _compare(array[base + m], key);
      if (order < 0) {
        lastOfs = m + 1;
      } else {
        offset = m;
      }
    }
    return offset;
  }

  // array-sort.tq: GallopRight
  int _gallopRight(List<T> array, T key, int base, int length, int hint) {
    var lastOfs = 0;
    var offset = 1;
    final baseHintElement = array[base + hint];
    var order = _compare(key, baseHintElement);
    if (order < 0) {
      final maxOfs = hint + 1;
      while (offset < maxOfs) {
        final offsetElement = array[base + hint - offset];
        order = _compare(key, offsetElement);
        if (order >= 0) break;
        lastOfs = offset;
        offset = (offset << 1) + 1;
        if (offset <= 0) offset = maxOfs;
      }
      if (offset > maxOfs) offset = maxOfs;
      final tmp = lastOfs;
      lastOfs = hint - offset;
      offset = hint - tmp;
    } else {
      final maxOfs = length - hint;
      while (offset < maxOfs) {
        final offsetElement = array[base + hint + offset];
        order = _compare(key, offsetElement);
        if (order < 0) break;
        lastOfs = offset;
        offset = (offset << 1) + 1;
        if (offset <= 0) offset = maxOfs;
      }
      if (offset > maxOfs) offset = maxOfs;
      lastOfs += hint;
      offset += hint;
    }
    lastOfs++;
    while (lastOfs < offset) {
      final m = lastOfs + ((offset - lastOfs) >> 1);
      order = _compare(key, array[base + m]);
      if (order < 0) {
        offset = m;
      } else {
        lastOfs = m + 1;
      }
    }
    return offset;
  }

  void _copy(List<T> src, int srcPos, List<T> dst, int dstPos, int length) {
    if (length <= 0) return;
    // setRange copes with overlapping ranges of one list, as V8's Copy does.
    dst.setRange(dstPos, dstPos + length, src, srcPos);
  }

  // array-sort.tq: MergeLow
  void _mergeLow(int baseA, int lengthAArg, int baseB, int lengthBArg) {
    var lengthA = lengthAArg;
    var lengthB = lengthBArg;
    final tempArray = List<T>.of(work.sublist(baseA, baseA + lengthA));
    var dest = baseA;
    var cursorTemp = 0;
    var cursorB = baseB;
    work[dest++] = work[cursorB++];

    // 0: succeed, 1: copy B
    int finish() {
      if (--lengthB == 0) return 0;
      if (lengthA == 1) return 1;
      var mg = minGallop;
      while (true) {
        var nofWinsA = 0;
        var nofWinsB = 0;
        while (true) {
          final order = _compare(work[cursorB], tempArray[cursorTemp]);
          if (order < 0) {
            work[dest++] = work[cursorB++];
            ++nofWinsB;
            --lengthB;
            nofWinsA = 0;
            if (lengthB == 0) return 0;
            if (nofWinsB >= mg) break;
          } else {
            work[dest++] = tempArray[cursorTemp++];
            ++nofWinsA;
            --lengthA;
            nofWinsB = 0;
            if (lengthA == 1) return 1;
            if (nofWinsA >= mg) break;
          }
        }
        ++mg;
        var firstIteration = true;
        while (nofWinsA >= _minGallopWins ||
            nofWinsB >= _minGallopWins ||
            firstIteration) {
          firstIteration = false;
          mg = mg - 1 > 1 ? mg - 1 : 1;
          minGallop = mg;
          nofWinsA = _gallopRight(
            tempArray,
            work[cursorB],
            cursorTemp,
            lengthA,
            0,
          );
          if (nofWinsA > 0) {
            _copy(tempArray, cursorTemp, work, dest, nofWinsA);
            dest += nofWinsA;
            cursorTemp += nofWinsA;
            lengthA -= nofWinsA;
            if (lengthA == 1) return 1;
            if (lengthA == 0) return 0;
          }
          work[dest++] = work[cursorB++];
          if (--lengthB == 0) return 0;

          nofWinsB = _gallopLeft(
            work,
            tempArray[cursorTemp],
            cursorB,
            lengthB,
            0,
          );
          if (nofWinsB > 0) {
            _copy(work, cursorB, work, dest, nofWinsB);
            dest += nofWinsB;
            cursorB += nofWinsB;
            lengthB -= nofWinsB;
            if (lengthB == 0) return 0;
          }
          work[dest++] = tempArray[cursorTemp++];
          if (--lengthA == 1) return 1;
        }
        ++mg;
        minGallop = mg;
      }
    }

    final how = finish();
    if (how == 0) {
      if (lengthA > 0) _copy(tempArray, cursorTemp, work, dest, lengthA);
    } else {
      _copy(work, cursorB, work, dest, lengthB);
      work[dest + lengthB] = tempArray[cursorTemp];
    }
  }

  // array-sort.tq: MergeHigh
  void _mergeHigh(int baseA, int lengthAArg, int baseB, int lengthBArg) {
    var lengthA = lengthAArg;
    var lengthB = lengthBArg;
    final tempArray = List<T>.of(work.sublist(baseB, baseB + lengthB));
    var dest = baseB + lengthB - 1;
    var cursorTemp = lengthB - 1;
    var cursorA = baseA + lengthA - 1;
    work[dest--] = work[cursorA--];

    // 0: succeed, 1: copy A
    int finish() {
      if (--lengthA == 0) return 0;
      if (lengthB == 1) return 1;
      var mg = minGallop;
      while (true) {
        var nofWinsA = 0;
        var nofWinsB = 0;
        while (true) {
          final order = _compare(tempArray[cursorTemp], work[cursorA]);
          if (order < 0) {
            work[dest--] = work[cursorA--];
            ++nofWinsA;
            --lengthA;
            nofWinsB = 0;
            if (lengthA == 0) return 0;
            if (nofWinsA >= mg) break;
          } else {
            work[dest--] = tempArray[cursorTemp--];
            ++nofWinsB;
            --lengthB;
            nofWinsA = 0;
            if (lengthB == 1) return 1;
            if (nofWinsB >= mg) break;
          }
        }
        ++mg;
        var firstIteration = true;
        while (nofWinsA >= _minGallopWins ||
            nofWinsB >= _minGallopWins ||
            firstIteration) {
          firstIteration = false;
          mg = mg - 1 > 1 ? mg - 1 : 1;
          minGallop = mg;
          var k = _gallopRight(
            work,
            tempArray[cursorTemp],
            baseA,
            lengthA,
            lengthA - 1,
          );
          nofWinsA = lengthA - k;
          if (nofWinsA > 0) {
            dest -= nofWinsA;
            cursorA -= nofWinsA;
            _copy(work, cursorA + 1, work, dest + 1, nofWinsA);
            lengthA -= nofWinsA;
            if (lengthA == 0) return 0;
          }
          work[dest--] = tempArray[cursorTemp--];
          if (--lengthB == 1) return 1;

          k = _gallopLeft(
            tempArray,
            work[cursorA],
            0,
            lengthB,
            lengthB - 1,
          );
          nofWinsB = lengthB - k;
          if (nofWinsB > 0) {
            dest -= nofWinsB;
            cursorTemp -= nofWinsB;
            _copy(tempArray, cursorTemp + 1, work, dest + 1, nofWinsB);
            lengthB -= nofWinsB;
            if (lengthB == 1) return 1;
            if (lengthB == 0) return 0;
          }
          work[dest--] = work[cursorA--];
          if (--lengthA == 0) return 0;
        }
        ++mg;
        minGallop = mg;
      }
    }

    final how = finish();
    if (how == 0) {
      if (lengthB > 0) {
        _copy(tempArray, 0, work, dest - (lengthB - 1), lengthB);
      }
    } else {
      dest -= lengthA;
      cursorA -= lengthA;
      _copy(work, cursorA + 1, work, dest + 1, lengthA);
      work[dest] = tempArray[cursorTemp];
    }
  }
}
