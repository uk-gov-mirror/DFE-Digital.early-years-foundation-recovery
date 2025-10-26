require 'rails_helper'

RSpec.describe FormBuilder do
  let(:setting_struct_class) do
    Struct.new(:name, :title, :active) do
      def active?
        ActiveModel::Type::Boolean.new.cast(active)
      end
    end
  end

  let(:assigns) { {} }
  let(:controller) { ActionController::Base.new }
  let(:lookup_context) { ActionView::LookupContext.new(nil) }
  let(:helper) { ActionView::Base.new(lookup_context, assigns, controller) }
  let(:object) { create :user }
  let(:object_name) { :user }
  let(:builder) { described_class.new(object_name, object, helper, {}) }
  let(:active_settings) do
    [
      setting_struct_class.new('active_one', 'Active One', true),
      setting_struct_class.new('active_two', 'Active Two', true),
    ]
  end

  describe '#select_trainee_setting' do
    subject(:output) { builder.select_trainee_setting }

    before do
      allow(Trainee::Setting).to receive(:active).and_return(active_settings)
      allow(Trainee::Setting).to receive(:by_name) do |name|
        (active_settings + [inactive_setting].compact).find { |setting| setting.name == name }
      end
    end

    let(:inactive_setting) { nil }

    it 'element' do
      expect(output).to include '<div class="govuk-form-group"'
      expect(output).to include 'name="user[setting_type_id]"'
    end

    it 'accessible label' do
      expect(output).to include 'Setting type'
    end

    it 'auto complete' do
      expect(output).to include 'No setting found'
    end

    it 'hint' do
      expect(output).to include 'Search for the type of setting or organisation you work in'
    end

    it 'options' do
      expect(output).to include(*active_settings.map(&:title))
    end

    context 'when the current selection is inactive' do
      let(:inactive_setting) do
        setting_struct_class.new('retired', 'Retired Setting', 'false')
      end

      before do
        object.setting_type_id = inactive_setting.name
      end

      it 'includes the inactive option so the user can keep their selection' do
        expect(output).to include inactive_setting.title
      end
    end
  end
end
