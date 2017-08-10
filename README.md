# Info

Rails db adapter for Impala layer over Kudu database.

# Usage

## Requirements

Active connection to Impala host and port 21000.

## Config database.yml

We need to config our yml like:

```
default: &default
  adapter: kudu
  host: 'localhost'
  port: 21000
  user: 'test'
  password: 'test'
  timeout: 5000
```

User and password not required.

## Supported migration functionality

With our adapter almost all migration functionality is supported, such as:

* create_table
* remove_table
* rename_table
* add_column
* remove_column
* rename_column
* and so on...

## Current limitations

* Creating any indexes (KUDU supports only primary key fields)

# Examples

Here is some examples...

## Create table

Because Kudu does not support AUTO INCREMENT INT fields we must ensure any primary key field is created as string field.

```
class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, primary_key: true
      t.string :account_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :company_id, null: false
      t.string :company_name
      t.timestamps
    end
  end
end
```

In example above we have only 1 primary key field and our model will work fully functionally when we using update(), delete() methods.

We can set additional primary key field, like

```
create_table :users, id: false do |t|
      t.string :id, primary_key: true
      t.string :account_id, primary_key: true
```

Here, we have two fields in primary key (id, account_id) and with KUDU table will be created with those 2 primary keys, but due to limitation of Rails will not be possible to use model delete(), update() methods.

## Add new column

Basic case:

```
class AddZipCodeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :zip_code, :string
  end
end
```

In case of adding new primary key field, like:

```
class AddCompanyToUsers < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :company_id, :string, primary_key: true
    reload_table_data :users, :company_id, default: '#company-id'
  end
  def down
    remove_column :users, :company_id
  end
end
```

we will initialize specialized method at migration side, and basically this will happen:

* New table "table_name_redefined" will be created based on original table name (ex. users -> users_redefined) with included new field, new primary key field.
* Old table "users" will be renamed to "users_temp"
* Data will be copied from users_temp => users with additional new field and default value
* Old temporary table "users_temp" will be deleted

## Delete column

Basic case:

```
class RemoveZipCodeFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :zip_code
  end
end
```

In case of deleting primary key field (existing) procedure is same like for adding new column with primary key.

## Model associations

Model associations will work without foreign keys, like:

```
class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts, id: false do |t|
      t.string :id, primary_key: true
      t.boolean :is_active, default: true
      t.timestamps
    end
  end
end

class Account < ApplicationRecord
  has_many :users, foreign_key: 'account_id'
end
```

and table Users with following construct...

```
class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, primary_key: true
      t.string :account_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :company_id, null: false
      t.string :company_name
      t.timestamps
    end
  end
end

class User < ApplicationRecord
  belongs_to :account, primary_key: 'id'
end
```

This way we're able to do

```
Account.first.users => [#User, #User, ...]
```

or

```
User.first.account => #Account
```
