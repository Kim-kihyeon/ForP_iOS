create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    email,
    nickname,
    preferred_categories,
    disliked_categories,
    preferred_themes,
    location,
    food_blacklist
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'full_name',
      '사용자'
    ),
    '{}',
    '{}',
    '{}',
    '',
    '{}'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

insert into public.users (
  id,
  email,
  nickname,
  preferred_categories,
  disliked_categories,
  preferred_themes,
  location,
  food_blacklist
)
select
  auth_users.id,
  coalesce(auth_users.email, ''),
  coalesce(
    auth_users.raw_user_meta_data ->> 'nickname',
    auth_users.raw_user_meta_data ->> 'full_name',
    '사용자'
  ),
  '{}',
  '{}',
  '{}',
  '',
  '{}'
from auth.users auth_users
left join public.users public_users on public_users.id = auth_users.id
where public_users.id is null
on conflict (id) do nothing;
