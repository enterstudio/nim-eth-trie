import
  rlp/types, constants

type
  NibblesRange* = object
    bytes: BytesRange
    ibegin, iend: int

proc initNibbleRange*(bytes: BytesRange): NibblesRange =
  result.bytes = bytes
  result.ibegin = 0
  result.iend = bytes.len * 2

const
  zeroNibblesRange* = initNibbleRange(zeroBytesRange)

proc `{}`(r: NibblesRange, pos: int): byte {.inline.} =
  ## This is a helper for a more raw access to the nibbles.
  ## It works with absolute positions.
  if pos > r.iend: raise newException(RangeError, "index out of range")
  return if (pos and 1) != 0: (r.bytes[pos div 2] and 0xf)
         else: (r.bytes[pos div 2] shr 4)

template `[]`*(r: NibblesRange, i: int): byte = r{r.ibegin + i}

proc len*(r: NibblesRange): int =
  r.iend - r.ibegin

proc `==`*(lhs, rhs: NibblesRange): bool =
  if lhs.len == rhs.len:
    for i in 0 ..< lhs.len:
      if lhs[i] != rhs[i]:
        return false
    return true
  else:
    return false

proc `$`*(r: NibblesRange): string =
  result = newStringOfCap(100)
  for i in r.ibegin ..< r.iend:
    let n = int r{i}
    let c = if n > 9: char(ord('a') + n)
            else: char(ord('0') + n)
    result.add c

proc slice*(r: NibblesRange, ibegin: int, iend = -1): NibblesRange =
  result.bytes = r.bytes
  result.ibegin = r.ibegin + ibegin
  let e = if iend < 0: r.iend + iend + 1
          else: r.ibegin + iend
  assert ibegin >= 0 and e <= result.bytes.len * 2
  result.iend = e

template writeFirstByte(nibbleCountExpr) {.dirty.} =
  let nibbleCount = nibbleCountExpr
  var oddnessFlag = (nibbleCount and 1) != 0
  newSeq(result, (nibbleCount div 2) + 1)
  result[0] = byte((int(isLeaf) * 2 + int(oddnessFlag)) shl 4)
  var writeHead = 0

template writeNibbles(r) {.dirty.} =
  for i in r.ibegin ..< r.iend:
    let nextNibble = r{i}
    if oddnessFlag:
      result[writeHead] = result[writeHead] or nextNibble
    else:
      inc writeHead
      result[writeHead] = nextNibble shl 4
    oddnessFlag = not oddnessFlag

proc hexPrefixEncode*(r: NibblesRange, isLeaf = false): Bytes =
  writeFirstByte(r.len)
  writeNibbles(r)

proc hexPrefixEncode*(r1, r2: NibblesRange, isLeaf = false): Bytes =
  writeFirstByte(r1.len + r2.len)
  writeNibbles(r1)
  writeNibbles(r2)

proc hexPrefixEncodeByte*(val: byte, isLeaf = false): byte =
  assert val < 16
  result = (((byte(isLeaf) * 2) + 1) shl 4) or val

proc sharedPrefixLen*(lhs, rhs: NibblesRange): int =
  result = 0
  while result < lhs.len and result < rhs.len:
    if lhs[result] != rhs[result]: break
    inc result

proc startsWith*(lhs, rhs: NibblesRange): bool =
  sharedPrefixLen(lhs, rhs) == rhs.len

proc hexPrefixDecode*(r: BytesRange): tuple[isLeaf: bool, nibbles: NibblesRange] =
  result.nibbles = initNibbleRange(r)
  if r.len > 0:
    result.isLeaf = (r[0] and 0x20) != 0
    let hasOddLen = (r[0] and 0x10) != 0
    result.nibbles.ibegin = 2 - int(hasOddLen)
  else:
    result.isLeaf = false

when false:
  proc keyOf(r: BytesRange): NibblesRange =
    let firstIdx = if r.len == 0: 0
                   elif (r[0] and 0x10) != 0: 1
                   else: 2

    return initNibbleRange(s).slice(firstIdx)

