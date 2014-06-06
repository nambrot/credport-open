class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :password_salt
      t.string :password_hash

      t.timestamps
    end
    # START n0=node(0),nx=node(*) MATCH n0-[r0?]-(),nx-[rx?]-() WHERE nx <> n0 DELETE r0,nx,rx;
  end
end
