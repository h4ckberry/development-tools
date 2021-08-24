# development-tools

#Usage

## Python

### firebase posting script

Creating an environment.
Check env.yaml for environment.

```shell
conda env create --file env.yaml.
```

Get credentials from firebase. (*****.jso)

```python
python firestore_create.py <credentials_path> <collection_name> <json_path> <uid_name> <uid_length>
```