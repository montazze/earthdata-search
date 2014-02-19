require "spec_helper"

describe "Granule search filters", reset: false do
  original_wait_time = nil
  before_granule_count = 0

  before(:all) do
    original_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 30 # Ugh, so slow

    Capybara.reset_sessions!
    visit "/search"
    fill_in "keywords", with: "ASTER L1A"
    expect(page).to have_content('ASTER L1A')

    first_dataset_result.click_link "Add dataset to the current project"

    dataset_results.click_link "View Project"

    expect(page).to have_content('Granules')

    first_project_dataset.click_link "Filter granules"

    number_granules = expect(page.text).to match /\d+ Granules/
    before_granule_count = number_granules.to_s.split(" ")[0].to_i
  end

  after(:all) do
    reset_overlay
    reset_project
    Capybara.default_wait_time = original_wait_time
  end

  context "when choosing a day/night flag" do
    after :each do
      select 'Anytime', from: "day-night-select"
      expect(page).to reset_granules_to(before_granule_count)
    end

    it "selecting day returns day granules" do
      select 'Day only', from: "day-night-select"
      expect(page).to filter_granules_from(before_granule_count)
    end

    it "selecting night returns night granules" do
      select 'Night only', from: "day-night-select"
      expect(page).to filter_granules_from(before_granule_count)
    end

    it "selecting both returns both day and night granules" do
      select 'Both day and night', from: "day-night-select"
      expect(page).to filter_granules_from(before_granule_count)
    end
  end

  context "when choosing cloud cover" do
    after :each do
      script = "edsc.page.project.datasets()[0].granuleQuery.cloud_cover_min('');edsc.page.project.datasets()[0].granuleQuery.cloud_cover_max('')"
      page.evaluate_script script
      expect(page).to reset_granules_to(before_granule_count)
    end

    it "filters with both min and max" do
      fill_in "Minimum:", with: "2.5"
      fill_in "Maximum:", with: "5.0"
      expect(page).to filter_granules_from(before_granule_count)
    end

    it "filters with only min" do
      fill_in "Minimum:", with: "2.5"
      expect(page).to filter_granules_from(before_granule_count)
    end

    it "filters with only max" do
      fill_in "Maximum:", with: "5.0"
      expect(page).to filter_granules_from(before_granule_count)
    end

    context "validates input" do
      it "minimum must be more than 0.0" do
        fill_in "Minimum", with: "-1.0"
        fill_in "Maximum", with: ""
        page.find(".master-overlay-secondary-content").click
        expect(page).to have_content "Value must be between 0.0 and 100.0"
      end

      it "maximum must be less than 100.0" do
        fill_in "Minimum", with: ""
        fill_in "Maximum", with: "110.0"
        page.find(".master-overlay-secondary-content").click
        expect(page).to have_content "Value must be between 0.0 and 100.0"
      end

      it "minimum must be less than maximum" do
        fill_in "Minimum", with: "5.0"
        fill_in "Maximum", with: "1.0"
        page.find(".master-overlay-secondary-content").click
        expect(page).to have_content "Minimum must be less than Maximum"
      end
    end
  end
end