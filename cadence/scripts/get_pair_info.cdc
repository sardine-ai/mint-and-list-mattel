import "SwapFactory"

access(all) fun main(token0Key: String, token1Key: String): AnyStruct? {
  return SwapFactory.getPairInfo(token0Key: token0Key, token1Key: token1Key)
}