#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require "test_helper"

# Comments controller tests.
class CommentsControllerTest < ActionController::TestCase
  setup do
    @comment = comments(:author_comment)
  end

  test "xhr request should create comment" do
    assert_difference("Comment.count") do
      xhr(:post,
          :create,
          { comment: { text: @comment.text, author_id: authors("haeckel") } },
          username: "fred",
          user_full_name: "Fred Jones",
          groups: ["edit"])
    end
    # assert_redirected_to comment_path(assigns(:comment))
  end

  test "should not show comment" do
    get(:show,
        { id: @comment },
        username: "fred",
        user_full_name: "Fred Jones",
        groups: ["edit"])
    assert_response :service_unavailable
  end

  test "should not get edit" do
    get(:edit,
        { id: @comment },
        username: "fred",
        user_full_name: "Fred Jones",
        groups: ["edit"])
    assert_response :service_unavailable
  end

  test "xhr request should destroy comment" do
    assert_difference("Comment.count", -1) do
      xhr(:delete,
          :destroy,
          { id: @comment },
          username: "fred",
          user_full_name: "Fred Jones",
          groups: ["edit"])
    end
  end

  test "html request should not destroy comment" do
    assert_no_difference("Comment.count") do
      delete(:destroy,
             { id: @comment },
             username: "fred",
             user_full_name: "Fred Jones",
             groups: ["edit"])
    end
    assert_response :service_unavailable
  end
end
