var EISDIR, ENOENT, ENOTDIR, Module, create_stats, fs, fs_exists_sync, fs_read_file_sync, fs_readdir_sync, fs_realpath_sync, fs_stat_sync, get_encoding, get_file, get_file_ref, path, wrap;

Module = require('module');

if (Module.__trojan_source__ != null) {
  return;
}

Module.__trojan_source__ = {};

fs = require('fs');

path = require('path');

ENOENT = function(filename) {
  var err;
  err = new Error("ENOENT, no such file or directory '" + filename + "'");
  err.code = 'ENOENT';
  return err;
};

EISDIR = function(filename) {
  var err;
  err = new Error("EISDIR, illegal operation on a directory");
  err.code = 'EISDIR';
  return err;
};

ENOTDIR = function(filename) {
  var err;
  err = new Error("ENOTDIR, not a directory '" + filename + "'");
  err.code = 'ENOTDIR';
  return err;
};

get_file_ref = function(filename) {
  var a, b, i, max, _i, _len;
  a = Object.keys(Module.__trojan_source__).map(function(f) {
    if (!(filename.length > f.length)) {
      return null;
    }
    if (f + '/' !== filename.slice(0, f.length + 1)) {
      return null;
    }
    return {
      root: f,
      path: filename.slice(f.length)
    };
  }).filter(function(f) {
    return f != null;
  });
  if (a.length === 0) {
    return null;
  }
  max = a[0].root.length;
  b = a[0];
  for (_i = 0, _len = a.length; _i < _len; _i++) {
    i = a[_i];
    if (i.root.length > max) {
      max = i.root.length;
      b = i;
    }
  }
  return {
    tree: Module.__trojan_source__[b.root],
    path: b.path
  };
};

get_file = function(filename) {
  var o, res, _ref;
  o = get_file_ref(filename);
  res = {
    is_packaged: o != null
  };
  if ((o != null ? o.path : void 0) != null) {
    res.path = o != null ? o.path : void 0;
  }
  if ((o != null ? (_ref = o.tree) != null ? _ref[o.path] : void 0 : void 0) != null) {
    res.file = o.tree[o.path];
  }
  return res;
};

get_encoding = function(encoding_or_options) {
  if (encoding_or_options == null) {
    return null;
  }
  if (typeof encoding_or_options === 'string') {
    return encoding_or_options;
  }
  if (encoding_or_options.encoding != null) {
    return encoding_or_options.encoding;
  }
  return null;
};

create_stats = function(o) {
  var stat;
  stat = {};
  ['dev', 'mode', 'nlink', 'uid', 'gid', 'rdev', 'blksize', 'ino', 'size', 'blocks'].forEach(function(k) {
    return stat[k] = o[k];
  });
  ['atime', 'mtime', 'ctime'].forEach(function(k) {
    return stat[k] = new Date(o[k]);
  });
  ['isFile', 'isDirectory', 'isBlockDevice', 'isCharacterDevice', 'isSymbolicLink', 'isFIFO', 'isSocket'].forEach(function(k) {
    return stat[k] = function() {
      return o[k];
    };
  });
  return stat;
};

fs_readdir_sync = function(old_fn, filename) {
  var o;
  o = get_file(filename);
  if (!o.is_packaged) {
    return old_fn(filename);
  }
  if (o.file == null) {
    throw ENOENT(filename);
  }
  if (o.file.type !== 'dir') {
    throw ENOTDIR(filename);
  }
  return o.file.children.map(function(f) {
    return f.slice(o.path.length + 1);
  });
};

fs_exists_sync = function(old_fn, filename) {
  var o;
  o = get_file(filename);
  if (!o.is_packaged) {
    return old_fn(filename);
  }
  return o.file != null;
};

fs_realpath_sync = function(old_fn, filename, cache) {
  if (get_file_ref(filename) == null) {
    return old_fn(filename);
  }
  return filename;
};

fs_read_file_sync = function(old_fn, filename, encoding_or_options) {
  var content, encoding, o;
  o = get_file(filename);
  if (!o.is_packaged) {
    return old_fn(filename, encoding_or_options);
  }
  if (o.file == null) {
    throw ENOENT(filename);
  }
  if (o.file.type === 'dir') {
    throw EISDIR(filename);
  }
  encoding = get_encoding(encoding_or_options);
  content = new Buffer(o.file.data, 'base64');
  if (encoding != null) {
    content = content.toString(encoding);
  }
  return content;
};

fs_stat_sync = function(old_fn, filename) {
  var o;
  o = get_file(filename);
  if (!o.is_packaged) {
    return old_fn(filename);
  }
  return create_stats(o.file.stat);
};

wrap = function(obj, method_name, fn) {
  var old_method;
  if (!((obj[method_name] != null) && typeof obj[method_name] === 'function')) {
    return;
  }
  old_method = obj[method_name].bind(obj);
  return obj[method_name] = function() {
    var args;
    args = Array.prototype.slice.call(arguments);
    return fn.apply(obj, [old_method].concat(args));
  };
};

wrap(fs, 'readFileSync', fs_read_file_sync);

wrap(fs, 'realpathSync', fs_realpath_sync);

wrap(fs, 'statSync', fs_stat_sync);

wrap(fs, 'lstatSync', fs_stat_sync);

wrap(fs, 'fstatSync', fs_stat_sync);

wrap(fs, 'existsSync', fs_exists_sync);

wrap(fs, 'readdirSync', fs_readdir_sync);
