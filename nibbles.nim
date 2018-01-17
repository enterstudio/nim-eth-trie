import
  rlp/types

type
  NibbleRange* = object
    bytes: BytesRange
    ibegin, iend: int

proc initNibbleRange*(bytes: BytesRange): NibbleRange =
  result.bytes = bytes
  result.ibegin = 0
  result.iend = bytes.len * 2

proc `[]`*(r: NibbleRange, i: int): Byte =
  let pos = r.ibegin + i
  if pos > last: raise newException(RangeError, "index out of range")

  return if (pos and 1) != 0: (r.bytes[pos div 2] and 0xf)
         else: (r.bytes[pos div 2] shr 4)

template len*(r: NibbleRange): int =
  r.iend - r.ibegin

proc slice*(r: NibbleRange, ibegin: int, iend = -1): NibbleRange =
  result.bytes = r.bytes
  result.ibegin = r.ibegin + ibegin
  let e = if iend < 0: r.iend + iend + 1
          else: r.ibegin + r.iend
  assert ibegin >= 0 and e <= result.bytes.len
  result.iend = e

proc hexPrefixEncode*(r: NibbleRange, isLeaf = false): Bytes =
  let nibbleCount = r.len
  var oddnessFlag = (nibbleCount and 1) != 0
  newSeq(result, (nibbleCount div 2) + 1)
  result[0] = (int(isLeaf) * 2 + int(oddnessFlag)) shl 4

  var writeHead = 0
  for i in r.ibegin ..< r.iend:
    let nextNibble = r[i]
    if oddnessFlag:
      result[writeHead] or= n
    else:
      inc writeHead
      result[writeHead] = nextNibble shl 4
    oddnessFlag = not oddnessFlag

proc hexPrefixDecode*(r: BytesRange): tuple[isLeaf: bool, nibbles: NibbleRange] =
  result.nibbles = initNibbleRange(r)
  if r.len > 0:
    result.isLeaf = (r[0] and 0x20) != 0
    let hasOddLen = (r[0] and 0x10) != 0
    result.nibbles.ibegin = 1 + int(hasOddLen)
  else:
    result.isLeaf = false

when false:
  proc keyOf(r: BytesRange): NibbleRange =
    let firstIdx = if r.len == 0: 0
                   elif (r[0] and 0x10) != 0: 1
                   else: 2

    return initNibbleRange(s).slice(firstIdx)

# Patricia procs

import rlp

proc isLeaf*(r: Rlp): bool =
  assert r.isList and r.listLen == 2
  let b = r.listItem(0).toBytes()
  return (b[0] and 0x20) != 0

