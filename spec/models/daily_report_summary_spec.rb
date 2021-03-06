# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DailyReportSummary do
  describe 'update_daily_report_summary' do

    it '日報を入力していると作成される' do
      FG.create(:daily_report_test011)

      DailyReportSummary.update_daily_report_summary('2014-01', '1')

      result_daily_report_summary = DailyReportSummary.all
      expect(result_daily_report_summary).to have(1).items
      expect(result_daily_report_summary[0].id).to eq(1)
      expect(result_daily_report_summary[0].succeed_count).to eq(1)
      expect(result_daily_report_summary[0].gross_profit_count).to eq(1)
      expect(result_daily_report_summary[0].interview_count).to eq(1)
      expect(result_daily_report_summary[0].new_meeting_count).to eq(1)
      expect(result_daily_report_summary[0].exist_meeting_count).to eq(1)
    end

    it '日報が入力されていないと更新されない' do
      DailyReportSummary.update_daily_report_summary('2014-01', '1')
      result_daily_report_summary = DailyReportSummary.all
      expect(result_daily_report_summary).to have(0).items
    end
  end

  describe 'get_summary_report' do

    def create_reports
        FG.create(:daily_report_summary_test011)
        FG.create(:daily_report_summary_test021)
        FG.create(:daily_report_summary_test022)
    end

    before(:each) do
      create_reports
    end

    before(:each) do
      self.use_transactional_fixtures = false
    end

    after(:each) do
      self.use_transactional_fixtures = true
    end

    describe '順次テスト' do

      it '集計期間:年次, 対象:なし, 集計方法:全体' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'year'
        daily_report_summary[:summary_target_flg] = nil
        daily_report_summary[:summary_method_flg] = 'summary'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(1).items
        expect(result_daily_report[0].succeed_count).to eq(93)
        expect(result_daily_report[0].gross_profit_count).to eq(93)
        expect(result_daily_report[0].interview_count).to eq(93)
        expect(result_daily_report[0].new_meeting_count).to eq(93)
        expect(result_daily_report[0].exist_meeting_count).to eq(93)
      end

      it '集計期間:年次, 対象:なし, 集計方法:個別' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'year'
        daily_report_summary[:summary_target_flg] = nil
        daily_report_summary[:summary_method_flg] = 'individual'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(2).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
        expect(result_daily_report[0].user_id).to eq(1)
        expect(result_daily_report[1].succeed_count).to eq(62)
        expect(result_daily_report[1].gross_profit_count).to eq(62)
        expect(result_daily_report[1].interview_count).to eq(62)
        expect(result_daily_report[1].new_meeting_count).to eq(62)
        expect(result_daily_report[1].exist_meeting_count).to eq(62)
        expect(result_daily_report[1].user_id).to eq(2)
      end

      it '集計期間:年次, 対象:1, 集計方法:全体' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'year'
        daily_report_summary[:summary_target_flg] = '1'
        daily_report_summary[:summary_method_flg] = 'summary'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(1).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
      end

      it '集計期間:年次, 対象:1, 集計方法:個別' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'year'
        daily_report_summary[:summary_target_flg] = '1'
        daily_report_summary[:summary_method_flg] = 'individual'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(1).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
        expect(result_daily_report[0].user_id).to eq(1)
      end

      it '集計期間:月次, 対象:なし, 集計方法:全体' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'month'
        daily_report_summary[:summary_target_flg] = nil
        daily_report_summary[:summary_method_flg] = 'summary'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(2).items
        expect(result_daily_report[0].succeed_count).to eq(62)
        expect(result_daily_report[0].gross_profit_count).to eq(62)
        expect(result_daily_report[0].interview_count).to eq(62)
        expect(result_daily_report[0].new_meeting_count).to eq(62)
        expect(result_daily_report[0].exist_meeting_count).to eq(62)
        expect(result_daily_report[1].succeed_count).to eq(31)
        expect(result_daily_report[1].gross_profit_count).to eq(31)
        expect(result_daily_report[1].interview_count).to eq(31)
        expect(result_daily_report[1].new_meeting_count).to eq(31)
        expect(result_daily_report[1].exist_meeting_count).to eq(31)
      end

      it '集計期間:月次, 対象:なし, 集計方法:個別' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'month'
        daily_report_summary[:summary_target_flg] = nil
        daily_report_summary[:summary_method_flg] = 'individual'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(3).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
        expect(result_daily_report[0].user_id).to eq(1)
        expect(result_daily_report[1].succeed_count).to eq(31)
        expect(result_daily_report[1].gross_profit_count).to eq(31)
        expect(result_daily_report[1].interview_count).to eq(31)
        expect(result_daily_report[1].new_meeting_count).to eq(31)
        expect(result_daily_report[1].exist_meeting_count).to eq(31)
        expect(result_daily_report[1].user_id).to eq(2)
        expect(result_daily_report[2].succeed_count).to eq(31)
        expect(result_daily_report[2].gross_profit_count).to eq(31)
        expect(result_daily_report[2].interview_count).to eq(31)
        expect(result_daily_report[2].new_meeting_count).to eq(31)
        expect(result_daily_report[2].exist_meeting_count).to eq(31)
        expect(result_daily_report[2].user_id).to eq(2)
      end

      it '集計期間:月次, 対象:1, 集計方法:全体' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'month'
        daily_report_summary[:summary_target_flg] = '1'
        daily_report_summary[:summary_method_flg] = 'summary'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(1).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
      end

      it '集計期間:月次, 対象:1, 集計方法:個別' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'month'
        daily_report_summary[:summary_target_flg] = '1'
        daily_report_summary[:summary_method_flg] = 'individual'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report.all).to have(1).items
        expect(result_daily_report[0].succeed_count).to eq(31)
        expect(result_daily_report[0].gross_profit_count).to eq(31)
        expect(result_daily_report[0].interview_count).to eq(31)
        expect(result_daily_report[0].new_meeting_count).to eq(31)
        expect(result_daily_report[0].exist_meeting_count).to eq(31)
        expect(result_daily_report[0].user_id).to eq(1)
      end
    end

    describe 'エラーテスト' do
      it '引数の値が指定とは違う場合nilが返ってくる' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'other'
        daily_report_summary[:summary_target_flg] = 'other'
        daily_report_summary[:summary_method_flg] = 'other'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '2014-01')

        expect(result_daily_report).to be_nil
      end

      it '対象の月のデータが存在しない場合空のリストが返ってくる' do
        daily_report_summary = Hash.new
        daily_report_summary[:summary_term_flg] = 'month'
        daily_report_summary[:summary_target_flg] = '1'
        daily_report_summary[:summary_method_flg] = 'summary'

        result_daily_report = DailyReportSummary.get_summary_report(daily_report_summary, '9999-01')

        expect(result_daily_report.all).to have(0).items
      end
    end
  end

  describe 'send_mail' do
    before(:all) do
      ActionMailer::Base.deliveries = []
    end

    before(:each) do
      @user = FG.create(:User)
      FG.create(:Employee)
      FG.create(:SysConfig_test001)
    end

    it '日報集計が作成されたらメール送信を行う' do
      FG.create(:daily_report_summary_test011)
      FG.create(:SysConfig_test002)

      DailyReportSummary.send_mail('2014-01', @user, 'test_domain')

      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it '日報集計が作成されたらメール送信を行う(ReturnPathが設定されていない)' do
      FG.create(:daily_report_summary_test011)

      DailyReportSummary.send_mail('2014-01', @user, 'test_domain')

      expect(ActionMailer::Base.deliveries.size).to eq(2)
    end

    it '日報集計が作成されていない場合メール送信は行われない' do
      FG.create(:SysConfig_test002)

      DailyReportSummary.send_mail('2014-01', @user, 'test_domain')

      expect(ActionMailer::Base.deliveries.size).to eq(2)
    end
  end
end
