// File: utils/ScanCodeService.ets

import promptAction from '@ohos.promptAction';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class ScanCodeService {
  private static instance: ScanCodeService | null = null;

  private constructor() {}

  public static getInstance(): ScanCodeService {
    if (!ScanCodeService.instance) {
      ScanCodeService.instance = new ScanCodeService();
    }
    return ScanCodeService.instance;
  }

  public async startScan(context: common.UIAbilityContext): Promise<string> {
    return new Promise((resolve, reject) => {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: true,
        enableAlbum: true
      };

      scanBarcode.startScanForResult(context, options)
        .then((result: scanBarcode.ScanResult) => {
          resolve(result.originalValue);
        })
        .catch((error: BusinessError) => {
          reject(error);
        });
    });
  }

  public async startScanWithToast(context: common.UIAbilityContext): Promise<void> {
    try {
      const result = await this.startScan(context);
      promptAction.showToast({ message: '扫描结果: ' + result });
    } catch (error) {
      promptAction.showToast({ message: '扫码取消或失败' });
    }
  }
}
