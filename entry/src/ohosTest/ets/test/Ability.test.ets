import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    // 定义一个测试套件.支持两个参数：测试套件名称和测试套件函数
    beforeAll(() => {
      // 预设一个行为，只在测试套件的所有测试用例开始前执行一次。
      // 此 API 仅支持一个参数：预设操作功能。
    })
    beforeEach(() => {
      // 预设一个动作，该动作在每个单元测试用例开始之前执行。
      // 执行次数与由 **it** 定义的测试用例数量相同。
      // 该 API 仅支持一个参数：预设动作函数。
    })
    afterEach(() => {
      // 预设一个清理动作，在每个单元测试用例结束后执行。
      // 执行次数与由 **it** 定义的测试用例数量相同。
      // 此 API 仅支持一个参数：清理动作函数。
    })
    afterAll(() => {
      // 预设一个清除操作，该操作在测试套件的所有测试用例结束后执行。
      // 此 API 仅支持一个参数：清除操作函数。
    })
    it('assertContain', 0, () => {
      // 定义一个测试用例。该 API 支持三个参数：测试用例名称、过滤参数和测试用例函数。
      hilog.info(0x0000, 'testTag', '%{public}s', 'it begin');
      let a = 'abc';
      let b = 'b';
      // 定义了一系列断言方法，用于声明期望的布尔条件。
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    })
  })
}