import { searchData } from '../../model/SearchData';
import router from '@ohos.router';
import { BreakpointSystem } from '../../utils/BreakpointSystem';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { VoiceInputDialog } from '../dialogs/VoiceInputDialog';

PersistentStorage.persistProp('searchHistory', []);
PersistentStorage.persistProp('initialSearchKeyword', '');

interface HotSearchItem {
  title: string;
  isHot: boolean;
}

interface SearchSuggestion {
  text: string;
  type: 'history' | 'suggestion' | 'hot';
}

@Component
export struct SearchPage {
  @Link isPresented: boolean;
  @Link startVoiceInput: boolean;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  private debounceTimer: number = -1;
  private readonly DEBOUNCE_DELAY: number = 300;

  @StorageLink('searchHistory') searchHistory: string[] = [];
  @StorageLink('initialSearchKeyword') initialSearchKeyword: string = '';

  @State searchText: string = '';
  @State searchSuggestions: SearchSuggestion[] = [];
  @State isSearching: boolean = false;

  @State searchDiscovery: string[] = [
    '靠死亡游戏混饭吃', '咒术回战', '药屋少女的呢喃', 'ak47',
    '葬送的芙莉莲', '嘉立创eda', '女友特别特别喜欢我',
    'ヨルシカ 茜', 'killkiss'
  ];

  @State hotSearchList: HotSearchItem[] = [
    { title: '央视马年春节节目单', isHot: true },
    { title: '2026拜年纪正在直播中', isHot: true },
    { title: '时代少年团少年晚来了', isHot: true },
    { title: '探班春晚后台', isHot: true },
    { title: 'PGL赛户小组赛Day3', isHot: true },
    { title: '我的世界新春会', isHot: true },
    { title: '马年新春慢直播', isHot: true },
    { title: '敬汉卿鸵鸟蛋终于成功了', isHot: false },
    { title: '凡人新春会杨洋送祝福', isHot: false },
    { title: '当代年轻人过年回家现状', isHot: true }
  ];

  voiceController: CustomDialogController = new CustomDialogController({
    builder: VoiceInputDialog({
      onClose: () => {
        this.startVoiceInput = false;
      },
      onResult: (text: string) => {
        this.searchText = text;
        this.startVoiceInput = false;
        this.performSearch(text);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true,
    cancel: () => {
      this.startVoiceInput = false;
    }
  });

  aboutToAppear() {
    this.breakpointSystem.register();
    
    if (this.startVoiceInput) {
      setTimeout(() => {
        this.voiceController.open();
      }, 500);
    }

    if (this.initialSearchKeyword && this.initialSearchKeyword.trim().length > 0) {
      const keyword = this.initialSearchKeyword;
      this.initialSearchKeyword = '';
      setTimeout(() => {
        this.searchText = keyword;
        this.performSearch(keyword);
      }, 300);
    }
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }
  }

  private createSuggestion(text: string, type: 'history' | 'suggestion' | 'hot'): SearchSuggestion {
    return { text: text, type: type };
  }

  private updateSearchSuggestions(query: string): void {
    if (query.length === 0) {
      this.searchSuggestions = [];
      return;
    }

    const suggestions: SearchSuggestion[] = [];
    const lowerQuery = query.toLowerCase();

    const historyMatches: SearchSuggestion[] = this.searchHistory
      .filter(item => item.toLowerCase().includes(lowerQuery))
      .slice(0, 3)
      .map((item: string) => this.createSuggestion(item, 'history'));

    suggestions.push(...historyMatches);

    const dataMatches: SearchSuggestion[] = searchData
      .filter(item => item.toLowerCase().includes(lowerQuery))
      .filter(item => !historyMatches.some(h => h.text === item))
      .slice(0, 7)
      .map((item: string) => this.createSuggestion(item, 'suggestion'));

    suggestions.push(...dataMatches);
    this.searchSuggestions = suggestions;
  }

  private debouncedSearch(value: string): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => {
      this.updateSearchSuggestions(value);
    }, this.DEBOUNCE_DELAY);
  }

  performSearch(value: string): void {
    const trimmedValue = value.trim();
    if (trimmedValue.length === 0) return;

    const history = [...this.searchHistory];
    const index = history.indexOf(trimmedValue);
    if (index !== -1) {
      history.splice(index, 1);
    }
    history.unshift(trimmedValue);
    
    if (history.length > 20) {
      history.length = 20;
    }
    this.searchHistory = history;

    router.pushUrl({
      url: 'pages/SearchResultPage',
      params: { keyword: trimmedValue }
    });
    this.isPresented = false;
  }

  clearHistory(): void {
    AlertDialog.show({
      title: '提示',
      message: '确定要清空搜索历史吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        fontColor: '#FF0000',
        action: () => {
          this.searchHistory = [];
        }
      }
    });
  }

  removeHistoryItem(item: string): void {
    const history = [...this.searchHistory];
    const index = history.indexOf(item);
    if (index !== -1) {
      history.splice(index, 1);
      this.searchHistory = history;
    }
  }

  @Builder
  SearchBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333'])
        .margin({ right: 16 })
        .onClick(() => {
          this.isPresented = false;
        })

      Search({ value: this.searchText, placeholder: '关键词' })
        .id('searchInput')
        .defaultFocus(true)
        .layoutWeight(1)
        .height(40)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : '#F5F5F5')
        .searchButton('搜索')
        .onAppear(() => {
          setTimeout(() => {
            focusControl.requestFocus('searchInput');
          }, 500);
        })
        .onChange((value: string) => {
          this.searchText = value;
          this.debouncedSearch(value);
        })
        .onSubmit((value: string) => {
          this.performSearch(value);
        })

      SymbolGlyph($r('sys.symbol.mic'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'])
        .margin({ left: 12 })
        .onClick(() => {
          this.voiceController.open();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 16 })
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
  }

  @Builder
  SuggestionItem(suggestion: SearchSuggestion) {
    Row() {
      if (suggestion.type === 'history') {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(16)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'])
          .margin({ right: 12 })
      } else {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(16)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'])
          .margin({ right: 12 })
      }

      Text(suggestion.text)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
        .layoutWeight(1)

      if (suggestion.type === 'history') {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(14)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#CCCCCC'])
          .onClick(() => {
            this.removeHistoryItem(suggestion.text);
          })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.searchText = suggestion.text;
      this.performSearch(suggestion.text);
    })
  }

  @Builder
  SearchSuggestionsList() {
    List() {
      ForEach(this.searchSuggestions, (suggestion: SearchSuggestion) => {
        ListItem() {
          this.SuggestionItem(suggestion)
        }
      }, (suggestion: SearchSuggestion) => `${suggestion.text}_${suggestion.type}`)
    }
    .width('100%')
    .layoutWeight(1)
    .divider({
      strokeWidth: 1,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
      startMargin: 44,
      endMargin: 16
    })
  }

  @Builder
  HistorySection() {
    Column({ space: 12 }) {
      Row() {
        Text('搜索历史')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
          .layoutWeight(1)

        Text('清除')
          .fontSize(12)
          .fontColor(Color.Gray)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F5F5F5')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
          .onClick(() => {
            this.clearHistory();
          })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.searchHistory, (item: string) => {
          Row() {
            Text(item)
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
            Text('×')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 8 })
              .onClick(() => {
                this.removeHistoryItem(item);
              })
          }
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#FFFFFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .margin({ right: 10, bottom: 10 })
          .onClick(() => {
            this.searchText = item;
            this.performSearch(item);
          })
        }, (item: string) => item)
      }
    }
    .width('100%')
  }

  @Builder
  DiscoverySection() {
    Column({ space: 12 }) {
      Text('搜索发现')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.searchDiscovery, (item: string) => {
          Text(item)
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              this.searchText = item;
              this.performSearch(item);
            })
        }, (item: string) => item)
      }
    }
    .width('100%')
  }

  @Builder
  HotSearchSection() {
    Column({ space: 12 }) {
      Text('热搜')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
        .width('100%')

      Column({ space: 12 }) {
        ForEach(this.hotSearchList, (item: HotSearchItem, index: number) => {
          Row() {
            if (index < 3) {
              SymbolGlyph($r('sys.symbol.flame'))
                .fontSize(16)
                .fontColor(['#FF0000'])
                .margin({ right: 4 })
            }

            Text(`${index + 1}.`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(index < 3 ? '#FF0000' : '#999999')
              .margin({ right: 12 })

            Text(item.title)
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
              .layoutWeight(1)

            if (item.isHot) {
              Text('热')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor('#FF0000')
                .borderRadius(4)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.searchText = item.title;
            this.performSearch(item.title);
          })
        })
      }
    }
    .width('100%')
  }

  @Builder
  TabletLayout() {
    Scroll() {
      Column({ space: 24 }) {
        Row() {
          Column({ space: 16 }) {
            Text('热搜')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
              .width('100%')

            Grid() {
              ForEach(this.hotSearchList, (item: HotSearchItem, index: number) => {
                GridItem() {
                  Row() {
                    if (index < 3) {
                      SymbolGlyph($r('sys.symbol.flame'))
                        .fontSize(16)
                        .fontColor(['#FF0000'])
                        .margin({ right: 4 })
                    }

                    Text(`${index + 1}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(index < 3 ? '#FF0000' : '#999999')
                      .width(index < 3 ? 16 : 24)
                      .textAlign(TextAlign.Start)

                    Text(item.title)
                      .fontSize(15)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    if (item.isHot) {
                      Text('热')
                        .fontSize(10)
                        .fontColor(Color.White)
                        .backgroundColor('#FF621F')
                        .borderRadius(4)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .margin({ left: 8 })
                    }
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .padding({ top: 10, bottom: 10 })
                }
                .onClick(() => {
                  this.searchText = item.title;
                  this.performSearch(item.title);
                })
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(8)
            .columnsGap(32)
            .height(240)
          }
          .layoutWeight(5)
          .alignItems(HorizontalAlign.Start)
          .padding({ right: 32 })

          Column({ space: 16 }) {
            Row() {
              Text('搜索历史')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
              Blank()
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(18)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'])
                .onClick(() => {
                  this.clearHistory();
                })
            }
            .width('100%')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.searchHistory, (item: string) => {
                Text(item)
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
                  .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#FFFFFF')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .margin({ right: 12, bottom: 12 })
                  .onClick(() => {
                    this.searchText = item;
                    this.performSearch(item);
                  })
              }, (item: string) => item)
            }
          }
          .layoutWeight(5)
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Top)
        .width('100%')

        this.DiscoverySection()
      }
      .padding({ left: 32, right: 32, top: 0, bottom: 24 })
      .width('100%')
    }
    .layoutWeight(1)
    .align(Alignment.Top)
  }

  @Builder
  MobileLayout() {
    Scroll() {
      Column({ space: 24 }) {
        if (this.searchHistory.length > 0) {
          this.HistorySection()
        }
        this.DiscoverySection()
        this.HotSearchSection()
      }
      .padding(16)
    }
    .layoutWeight(1)
    .align(Alignment.Top)
  }

  build() {
    Column() {
      this.SearchBar()

      if (this.searchText.length > 0) {
        this.SearchSuggestionsList()
      } else {
        if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
          this.TabletLayout()
        } else {
          this.MobileLayout()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }
}