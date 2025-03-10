module HelloPlugin

using Genie

"""
Functionality for authenticating Genie users.
"""

import Genie

export authenticate, deauthenticate, is_authenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication, @authenticated!

const USER_ID_KEY = :__auth_user_id


"""
Stores the user id on the session.
"""
function authenticate(user_id::Any, session::Genie.Sessions.Session) :: Genie.Sessions.Session
  Genie.Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::String, session::Genie.Sessions.Session)
  authenticate(Int(user_id.value), session)
end
function authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Genie.Sessions.Session
  authenticate(user_id, params[:SESSION])
end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
Removes the user id from the session.
"""
function deauthenticate(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  Genie.Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict = Genie.Requests.payload()) :: Genie.Sessions.Session
  deauthenticate(params[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool
Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session::Union{Genie.Sessions.Session,Nothing}) :: Bool
  Genie.Sessions.isset(session, USER_ID_KEY)
end
function is_authenticated(params::Dict = Genie.Requests.payload()) :: Bool
  is_authenticated(params[:SESSION])
end

const authenticated = is_authenticated


"""
    @authenticate!(exception::E = ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
If the current request is not authenticated it throws an ExceptionalResponse exception.
"""
macro authenticated!(exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  :(GenieAuthentication.authenticated() || throw($exception))
end


"""
    get_authentication(session) :: Union{Nothing,Any}
    get_authentication(params::Dict{Symbol,Any}) :: Union{Nothing,Any}
Returns the user id stored on the session, if available.
"""
function get_authentication(session::Genie.Sessions.Session) :: Union{Nothing,Any}
  Genie.Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict = Genie.Requests.payload()) :: Union{Nothing,Any}
  get_authentication(params[:SESSION])
end

const authentication = get_authentication


"""
    login(user, session) :: Union{Nothing,Genie.Sessions.Session}
    login(user, params::Dict{Symbol,Any}) :: Union{Nothing,Genie.Sessions.Session}
Persists on session the id of the user object and returns the session.
"""
#function login(user::M, session::Genie.Sessions.Session)::Union{Nothing,Genie.Sessions.Session} where {M<:SearchLight.AbstractModel}
#  authenticate(getfield(user, Symbol(pk(user))), session)
#end
#function login(user::M, params::Dict = Genie.Requests.payload())::Union{Nothing,Genie.Sessions.Session} where {M<:SearchLight.AbstractModel}
#  login(user, params[:SESSION])
#end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session
Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  deauthenticate(session)
end
function logout(params::Dict = Genie.Requests.payload()) :: Genie.Sessions.Session
  logout(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session::Union{Genie.Sessions.Session,Nothing})
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict = Genie.Requests.payload())
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})
Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session::Genie.Sessions.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict = Genie.Requests.payload())
  without_authentication(f, params[:SESSION])
end





function install(dest::String; force = false)
  src = abspath(normpath(joinpath(pathof(@__MODULE__) |> dirname, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isdir(joinpath(src, f))|| continue
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end

end # module
