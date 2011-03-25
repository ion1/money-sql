begin;
  create table users (
    id serial primary key,
    name text not null);
  create unique index users_name_index on users (name);

  create table exchanges (
    id serial primary key,
    from_user_id integer not null references users (id) on delete cascade,
    to_user_id integer not null references users (id) on delete cascade,
    "timestamp" timestamp with time zone not null,
    value numeric not null,
    comment text,
    constraint positive_value check (value > 0),
    constraint from_to_user_ids_differ check (from_user_id != to_user_id));
  create index exchanges_from_user_id_index on exchanges (from_user_id);
  create index exchanges_to_user_id_index on exchanges (to_user_id);
  create index exchanges_timestamp_index on exchanges ("timestamp");

  create function insert_exchange (
    users.name%type,
    users.name%type,
    exchanges.timestamp%type,
    exchanges.value%type,
    exchanges.comment%type default null)
  returns integer
  volatile
  language SQL
  as $$
    insert into exchanges (
      from_user_id, to_user_id, "timestamp", value, comment)
    values (
      (select id from users where name=$1),
      (select id from users where name=$2),
      $3, $4, $5)
    returning id $$;

  create function exchanges_with_user (users.id%type)
  returns setof exchanges
  language plpgsql
  as $$
    declare
      r exchanges%rowtype;
      temp users.id%type;
    begin
      for r in select * from exchanges
      where from_user_id=$1 or to_user_id=$1
      loop
        if r.from_user_id=$1 then
          temp = r.to_user_id;
          r.to_user_id = r.from_user_id;
          r.from_user_id = temp;
          r.value = -r.value;
        end if;
        return next r;
      end loop;
      return;
    end
  $$;
commit;

-- vim:set et sw=2 sts=2:
