# frozen_string_literal: true

require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @task = create(:task, user: @user)
  end

  def test_values_of_created_at_and_updated_at
    task = Task.new(title: "This is a test task", user: @user)
    assert_nil task.created_at
    assert_nil task.updated_at

    task.save!
    assert_not_nil task.created_at
    assert_equal task.updated_at, task.created_at

    task.update!(title: "This is a updated task")
    assert_not_equal task.updated_at, task.created_at
  end

  def test_task_should_not_be_valid_without_user
    @task.user = nil
    assert_not @task.save
    assert_includes @task.errors.full_messages, "User must exist"
  end

  def test_task_title_should_not_exceed_maximum_length
    @task.title = "a" * 100
    assert_not @task.valid?
  end

  def test_task_count_increases_on_saving
    assert_difference ["Task.count"] do
      create(:task)
    end
  end

  def test_task_should_not_be_valid_without_title
    @task.title = ""
    assert @task.invalid?
  end

  def test_task_slug_is_parameterized_title
    title = @task.title
    @task.save!
    assert_equal title.parameterize, @task.slug
  end

  def test_task_slug_is_parameterized_title
    title = @task.title
    @task.save!
    assert_equal title.parameterize, @task.slug
  end

  def test_incremental_slug_generation_for_tasks_with_duplicate_two_worded_titles
    first_task = Task.create!(title: "test task", user: @user)
    second_task = Task.create!(title: "test task", user: @user)

    assert_equal "test-task", first_task.slug
    assert_equal "test-task-2", second_task.slug
  end

  def test_incremental_slug_generation_for_tasks_with_duplicate_hyphenated_titles
    first_task = Task.create!(title: "test-task", user: @user)
    second_task = Task.create!(title: "test-task", user: @user)

    assert_equal "test-task", first_task.slug
    assert_equal "test-task-2", second_task.slug
  end

  def test_slug_generation_for_tasks_having_titles_one_being_prefix_of_the_other
    first_task = Task.create!(title: "fishing", user: @user)
    second_task = Task.create!(title: "fish", user: @user)

    assert_equal "fishing", first_task.slug
    assert_equal "fish", second_task.slug
  end

  def test_error_raised_for_duplicate_slug
    another_test_task = Task.create!(title: "another test task", user: @user)

    assert_raises ActiveRecord::RecordInvalid do
      another_test_task.update!(slug: @task.slug)
    end

    error_msg = another_test_task.errors.full_messages.to_sentence
    assert_match t("task.slug.immutable"), error_msg
  end

  def test_updating_title_does_not_update_slug
    assert_no_changes -> { @task.reload.slug } do
      updated_task_title = "updated task title"
      @task.update!(title: updated_task_title)
      assert_equal updated_task_title, @task.title
    end
  end

  def test_slug_suffix_is_maximum_slug_count_plus_one_if_two_or_more_slugs_already_exist
    title = "test-task"
    first_task = Task.create!(title: title, user: @user)
    second_task = Task.create!(title: title, user: @user)
    third_task = Task.create!(title: title, user: @user)
    fourth_task = Task.create!(title: title, user: @user)

    assert_equal fourth_task.slug, "#{title.parameterize}-4"

    third_task.destroy

    expected_slug_suffix_for_new_task = fourth_task.slug.split("-").last.to_i + 1

    new_task = Task.create!(title: title, user: @user)
    assert_equal new_task.slug, "#{title.parameterize}-#{expected_slug_suffix_for_new_task}"
  end

  def test_existing_slug_prefixed_in_new_task_title_doesnt_break_slug_generation
    title_having_new_title_as_substring = "buy milk and apple"
    new_title = "buy milk"

    existing_task = Task.create!(title: title_having_new_title_as_substring, user: @user)
    assert_equal title_having_new_title_as_substring.parameterize, existing_task.slug

    new_task = Task.create!(title: new_title, user: @user)
    assert_equal new_title.parameterize, new_task.slug
  end

  def test_having_numbered_slug_substring_in_title_doesnt_affect_slug_generation
    title_with_numbered_substring = "buy 2 apples"

    existing_task = Task.create!(title: title_with_numbered_substring, user: @user)
    assert_equal title_with_numbered_substring.parameterize, existing_task.slug

    substring_of_existing_slug = "buy"
    new_task = Task.create!(title: substring_of_existing_slug, user: @user)

    assert_equal substring_of_existing_slug.parameterize, new_task.slug
  end
end
