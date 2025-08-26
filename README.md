# Strong Params Basics

## What are Strong Params?

To understand the purpose of strong parameters, imagine you run a pharmacy. What would happen if you allowed all prescription orders to go through without checking for valid prescriptions or driver’s licenses? (Spoiler: you’d probably end up in jail.) It would be irresponsible to run a pharmacy without verifying that orders are legitimate. Similarly, Rails introduced strong parameters to address security vulnerabilities. Since Rails 4+, developers are required to whitelist the parameters that can be sent to the database from a form.

## Setup

In previous lessons, the strong parameter requirement was manually turned off to prevent confusion. Let’s first understand why strong parameters were created, and then work with them.

## Why Strong Params?

In this Rails app, strong parameters are _disabled_. Create a new Post by going to `/posts/new`. After creating the post, edit it at `/posts/1/edit`. You’ll notice there is no Description field! In this case, we don’t want users to be able to modify the description of a post once it’s been created. This scenario occurs in many real-world cases. For example, you wouldn’t want a bank user to edit their account number or balance, but those fields still exist on the account class. Here, `description` is still an attribute for the Post class. Let’s see if a user could "hack" the form to modify the `description`.

1. Right-click and inspect the page.
2. Find the input for title. It should look like: `<input type="text" value="asdferwer" name="post[title]" id="post_title">`
3. Right-click on the input and choose "Edit as HTML".
4. Add the following new Description field:

    ```html
    <br />
    <label>Description:</label>
    <br />
    <input
      type="text"
      value="malicious description"
      name="post[description]"
      id="post_description"
    />
    ```

5. Click somewhere else—now a description field appears.
6. Type a message into the new field.
7. Click submit. You’ll notice the description has been updated. This is a security issue!

Strong parameters were created to prevent this. We want to ensure that when users submit a form, only the fields we explicitly allow are processed.

## Code Implementation

Let’s enable strong parameters. Open `config/application.rb` and delete the line:
`config.action_controller.permit_all_parameters = true`.

Restart your Rails server and navigate to `localhost:3000/posts/new`. Fill out the form and click submit. You’ll see a `ForbiddenAttributesError`:

![ForbiddenAttributesError](https://s3.amazonaws.com/flatiron-bucket/readme-lessons/ForbiddenAttributesError.png)

This means Rails needs to be told which parameters are allowed to be submitted through the form to the database. By default, nothing is permitted.

The same error occurs if you try to update a record. To fix this, update the `create` and `update` methods as follows:

```ruby
# app/controllers/posts_controller.rb

def create
  @post = Post.new(params.require(:post).permit(:title, :description))
  @post.save
  redirect_to post_path(@post)
end

def update
  @post = Post.find(params[:id])
  @post.update(params.require(:post).permit(:title))
  redirect_to post_path(@post)
end
```

If you refresh the browser, both the `create` and `update` actions will work. Running the RSpec tests will show that the specs are passing. Notice that `update` only permits `:title`—this is because, given our forms, we only want the title to be editable. If you try the earlier hack again, it won’t work.

### Permit vs. Require

What’s the difference between `permit` and `require`? The `require` method is strict: it means the `params` must contain a key called "post". If it’s missing, the request fails. The `permit` method is more flexible: it allows only the specified keys to be accepted. If a key isn’t present, it’s simply ignored.

## DRYing up Strong Params

The code above is fine if you only have a `create` method. However, in a standard CRUD setup, you’ll also need to implement similar code in your `update` action. In our example, we had different code for `create` and `update`, but usually you want the same permitted fields. To avoid repetition, it’s standard Rails practice to abstract the strong parameter call into its own method:

```ruby
# app/controllers/posts_controller.rb

def create
  @post = Post.new(post_params)
  @post.save
  redirect_to post_path(@post)
end

def update
  @post = Post.find(params[:id])
  @post.update(post_params)
  redirect_to post_path(@post)
end

private

def post_params
  params.require(:post).permit(:title, :description)
end
```

Now, both `create` and `update` can simply call `post_params`. This is helpful because if you duplicated the strong parameter call in both methods, you’d need to update both every time the schema changes. By using a `post_params` method, you only need to update it in one place.

But what if you want to permit different fields for `create` and `update`? You can use a splat argument:

```ruby
# app/controllers/posts_controller.rb

def create
  @post = Post.new(post_params(:title, :description))
  @post.save
  redirect_to post_path(@post)
end

def update
  @post = Post.find(params[:id])
  @post.update(post_params(:title))
  redirect_to post_path(@post)
end

private

# Pass permitted fields as *args; this keeps `post_params` DRY while
# allowing different behavior depending on the action.
def post_params(*args)
  params.require(:post).permit(*args)
end
```

Test this in the browser: you can now create and update posts without errors, and all RSpec tests should pass.
