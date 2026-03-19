export class SidebarItemModel {
  title: string;
  icon: string;
  hasCount?: boolean;
  count?: number;

  constructor(title: string, icon: string, hasCount?: boolean, count?: number) {
    this.title = title;
    this.icon = icon;
    this.hasCount = hasCount;
    this.count = count;
  }
}
