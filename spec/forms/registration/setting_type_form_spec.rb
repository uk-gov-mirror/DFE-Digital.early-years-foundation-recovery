require 'rails_helper'

RSpec.describe Registration::SettingTypeForm do
  subject(:form) { described_class.new(user: user) }

  describe '#validate' do
    let(:user) { create(:user) }
    let(:errors) { form.errors[:setting_type_id] }

    before do
      allow(Trainee::Setting).to receive(:valid_types).and_return(%w[preschool active_setting other])
      form.setting_type_id = input
      form.validate
    end

    context 'without input' do
      let(:input) { '' }

      specify { expect(errors).to be_present }
    end

    context 'with invalid input' do
      let(:input) { 'university' }

      specify { expect(errors).to be_present }
    end

    context 'with inactive input matching the user selection' do
      let(:user) { create(:user, setting_type_id: 'retired_setting') }
      let(:input) { user.setting_type_id }

      before do
        allow(Trainee::Setting).to receive(:valid_types).and_return(%w[active_setting other])
      end

      specify { expect(errors).not_to be_present }
    end

    context 'with inactive input not matching the user selection' do
      let(:user) { create(:user, setting_type_id: 'active_setting') }
      let(:input) { 'retired_setting' }

      before do
        allow(Trainee::Setting).to receive(:valid_types).and_return(%w[active_setting other])
      end

      specify { expect(errors).to be_present }
    end

    context 'with valid input' do
      let(:input) { 'preschool' }

      specify { expect(errors).not_to be_present }
    end
  end

  describe '#save' do
    let(:user) do
      create :user, :independent_childminder,
             local_authority: 'Cambridgeshire County Council'
    end

    before do
      allow(Trainee::Setting).to receive(:by_name).and_call_original
      stubbed_setting = instance_double(
        Trainee::Setting,
        form_params: {
          setting_type_id: 'central_government',
          setting_type: 'Central government',
          setting_type_other: nil,
          local_authority: I18n.t(:na),
          role_type: I18n.t(:na),
        },
        has_role?: false,
      )
      allow(Trainee::Setting).to receive(:by_name).with('central_government').and_return(stubbed_setting)
      allow(Trainee::Setting).to receive(:valid_types).and_return(%w[central_government other])

      form.setting_type_id = 'central_government'
      form.save
    end

    it 'updates user details' do
      expect(user.setting_type_id).to eq 'central_government'
      expect(user.setting_type).to eq 'Central government'
      expect(user.local_authority).to eq 'Not applicable'
      expect(user.role_type).to eq 'Not applicable'
    end
  end
end
