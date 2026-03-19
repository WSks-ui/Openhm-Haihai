import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';

export class PhotoPickerService {
  private static instance: PhotoPickerService;

  private constructor() {}

  public static getInstance(): PhotoPickerService {
    if (!PhotoPickerService.instance) {
      PhotoPickerService.instance = new PhotoPickerService();
    }
    return PhotoPickerService.instance;
  }

  public async selectSingleImage(context: common.UIAbilityContext): Promise<string | null> {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        return photoSelectResult.photoUris[0];
      }
      return null;
    } catch (error) {
      console.error('PhotoPickerService selectSingleImage error:', JSON.stringify(error));
      promptAction.showToast({
        message: '选择图片失败，请重试',
        duration: 2000
      });
      return null;
    }
  }
}
