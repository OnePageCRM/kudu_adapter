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

* Changing (adding, renaming or deleting) of primary key fields after table is created
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
      t.string :account_id, primary_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :company_id, null: false
      t.string :company_name
      t.timestamps
    end
  end
end
```

Here, we have two fields in primary key (id, account_id)

## Add new column

```
class AddZipCodeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :zip_code, :string
  end
end
```

## Delete column

```
class RemoveZipCodeFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :zip_code
  end
end
```

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
      t.string :account_id, primary_key: true
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
