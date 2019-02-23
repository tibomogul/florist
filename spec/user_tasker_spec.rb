
#
# specifying florist
#
# Wed Feb 20 09:09:04 JST 2019
#

require 'spec_helper'


describe '::Florist' do

  before :each do

    @unit = Flor::Unit.new(
      loader:
        Flor::HashLoader,
      db_migrations:
        'spec/migrations',
      sto_uri:
        RUBY_PLATFORM.match(/java/) ?
        'jdbc:sqlite://tmp/florist_test.db' :
        'sqlite::memory:')
    @unit.conf['unit'] = 'utspec'
    #@unit.hook('journal', Flor::Journal)
    @unit.storage.delete_tables
    @unit.storage.migrate(allow_missing_migration_files: true)
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe '::UserTasker' do

    it 'assigns a task to a user' do

      @unit.add_tasker('alice', Florist::UserTasker)

      r = @unit.launch(
        %q{
          alice _
        },
        wait: 'task')

      expect(r['point']).to eq('task')
      expect(r['tasker']).to eq('alice')

      ts = @unit.storage.db[:florist_tasks].all
      as = @unit.storage.db[:florist_task_assignments].all

      expect(ts.size).to eq(1)
      expect(as.size).to eq(1)

      t, a = ts.first, as.first

      expect(t[:exid]).to eq(r['exid'])
      expect(t[:nid]).to eq(r['nid'])
      expect(t[:ctime]).not_to eq(nil)
      expect(t[:mtime]).not_to eq(nil)
      expect(t[:status]).to eq('created')

      expect(a[:task_id]).to eq(t[:id])
      expect(a[:type]).to eq('')
      expect(a[:resource_name]).to eq('alice')
      expect(a[:resource_type]).to eq('user')
      expect(a[:content]).to eq(nil)
      expect(a[:ctime]).not_to eq(nil)
      expect(a[:mtime]).not_to eq(nil)
      expect(a[:status]).to eq('active')

      m = Flor::Storage.from_blob(t[:content])
      expect(m['m']).to eq(r['m'])
    end
  end
end
