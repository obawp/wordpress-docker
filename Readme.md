## What's this?

This is a fast, simple and clean install for Wordpress with docker in few steps. 

## Customize

The PHP current version is 8.3 the but you can build your own image if do you want in your `Dockerfile`.

## Requirements

- Docker

## Configuring

- Create your `.env` based in `.env.example` file
- Create your `config/wp/config.extra.php` based in `config/wp/config.extra.sample.php` file
- Create your `config/custom-php.ini` based in `config/custom-php-sample.ini` file

## Usage

### Building the image

```bash
make build
```

### Creating the volume folder

```bash
make run
make mkdir
make rm
```

### Running docker compose

```bash
make up
```

### Add production linux permissions

```bash
make perm
```

### Add developer linux permissions (optional)

If you need edit the files do it.

```bash
make perm_dev
```

### Install Wordpress if not installed

```bash
make install
```


### Install SMTP

```bash
make smtp_install
```

To install the SMTP settings in your wp-config

```bash
make smtp_config
```

Or to install the SMTP settings in your database

```bash
make smtp_db
```

Test your email


```bash
make smtp_test
```


## Access

### Running in Localhost

#### Ubuntu

Use `0.0.0.0` to expose and `127.0.0.1` to local in your `.env` file

Go to `/etc/hosts` and add `127.0.0.1 wordpress.local` or `yo.ur.host.ip your.url` 

To Wordpress, access this url in the browser.

To PhpMyAdmin ou PgAdmin use `your.url:8081`


## Saving the image

Create a repository in the Docker Hub.

Be careful with the visibility of the repository, whether it is public or private. 

**If you do it without change the visibility in docker hub, it will be public.**

### Do the Docker Hub Login

```bash
make login
```

### Push

After build, you can push it:

```bash
make push
```
