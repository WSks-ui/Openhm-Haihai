import { Post } from '../../model/Post';
import { PostWaterFlow } from './PostWaterFlow';

@Component
export struct AllResultsView {
  @Prop searchResults: Post[] = [];

  build() {
    PostWaterFlow({ searchResults: this.searchResults })
  }
}
