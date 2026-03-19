import { Post } from '../../model/Post';
import { PostWaterFlow } from './PostWaterFlow';

@Component
export struct UserResultsView {
  @Prop searchResults: Post[] = [];

  build() {
    PostWaterFlow({ searchResults: this.searchResults })
  }
}
