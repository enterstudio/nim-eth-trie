import
  random, sets,
  rlp/types as rlpTypes, ranges/bitranges, nimcrypto/utils

type
  RandGen*[T] = object
    minVal, maxVal: T

  KVPair* = ref object
    key*: string
    value*: string

proc randGen*[T](minVal, maxVal: T): RandGen[T] =
  assert(minVal <= maxVal)
  result.minVal = minVal
  result.maxVal = maxVal

proc getVal*[T](x: RandGen[T]): T =
  if x.minVal == x.maxVal: return x.minVal
  rand(x.minVal..x.maxVal)

proc randString*(len: int): string =
  result = newString(len)
  for i in 0..<len:
    result[i] = rand(255).char

proc randPrimitives*[T](val: int): T =
  when T is string:
    randString(val)
  elif T is int:
    result = val

proc randList*(T: typedesc, strGen, listGen: RandGen, unique: bool = true): seq[T] =
  let listLen = listGen.getVal()
  result = newSeqOfCap[T](listLen)
  if unique:
    var set = initSet[T]()
    for len in 0..<listLen:
      while true:
        let x = randPrimitives[T](strGen.getVal())
        if x notin set:
          result.add x
          set.incl x
          break
  else:
    for len in 0..<listLen:
      let x = randPrimitives[T](strGen.getVal())
      result.add x

proc randKVPair*(keySize = 32): seq[KVPair] =
  const listLen = 100
  let keys = randList(string, randGen(keySize, keySize), randGen(listLen, listLen))
  let vals = randList(string, randGen(1, 100), randGen(listLen, listLen))

  result = newSeq[KVPair](listLen)
  for i in 0..<listLen:
    result[i] = KVPair(key: keys[i], value: vals[i])

proc toBytes*(str: string): Bytes =
  result = newSeq[byte](str.len)
  for i in 0..<str.len:
    result[i] = byte(str[i])

proc toBytesRange*(str: string): BytesRange =
  var s: seq[byte]
  if str[0] == '0' and str[1] == 'x':
    s = fromHex(str.substr(2))
  else:
    s = newSeq[byte](str.len)
    for i in 0 ..< str.len:
      s[i] = byte(str[i])
  result = s.toRange

proc genBitVec*(len: int): BitRange =
  let k = ((len + 7) and (not 7)) shr 3
  var s = newSeq[byte](k)
  result = bits(s, len)
  for i in 0..<len:
    result[i] = rand(2) == 1

