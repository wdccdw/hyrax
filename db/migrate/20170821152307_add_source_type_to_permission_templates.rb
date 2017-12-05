class AddSourceTypeToPermissionTemplates < ActiveRecord::Migration[4.2]
  # Recreate the permission_template_accesses table without the FKC on permission_templates.
  # This is required since the sqlite adapter will have to drop the permission_templates table
  # just to perform the upcoming column changes, which will violate the FKC.
  def sqlite_disable_fkc
    # Renaming the dependent column in sqlite actually recreates the table, silently dropping the fkc
    rename_column :permission_template_accesses, :permission_template_id, :permission_template_id_old
  end

  # Recreate the permission_template_accesses table with the FKC.
  def sqlite_restore_fkc
    change_table :permission_template_accesses do |t|
      t.references :permission_template, foreign_key: true
    end
    connection.execute("UPDATE permission_template_accesses SET permission_template_id=permission_template_id_old;")
    remove_column :permission_template_accesses, :permission_template_id_old
  end

  def up
    is_sql_lite = connection.adapter_name.downcase.starts_with?('sqlite')
    sqlite_disable_fkc if is_sql_lite

    # Separate admin_set_id into source_type/id
    add_column :permission_templates, :source_type, :string
    rename_column :permission_templates, :admin_set_id, :source_id
    Hyrax::PermissionTemplate.find_each do |permission_template|
      permission_template.source_type = 'admin_set'
      permission_template.save!
    end

    sqlite_restore_fkc if is_sql_lite
  end

  def down
    is_sql_lite = connection.adapter_name.downcase.starts_with?('sqlite')
    sqlite_disable_fkc if is_sql_lite

    # Recompose source_type/id into single field admin_set_id
    remove_column :permission_templates, :source_type
    rename_column :permission_templates, :source_id, :admin_set_id

    sqlite_restore_fkc if is_sql_lite
  end
end
