
express     = require 'express'
fs          = require 'fs'
multer      = require 'multer'
cson        = require 'cson'

util        = require 'app/util'
logger      = require 'app/logger'
  

module.exports = (opts) -> (ret) ->
  update_file_map = (id, info) ->
    data = cson.createCSONString "#{id}": info
    fs.appendFile opts.uploads + '/index.cson', data + '\n', logger.errNonNil

  fs.readFile opts.key_path, 'utf8', (err, data)->
    if err then return ret err, null

    upload_key = data.toString('utf8').trim()
    upload = multer dest:opts.uploads

    form_file_name = 'toSave'

    r = express.Router()
    r.get '/', (req, res) ->
      res.render 'upload',
        title: 'Upload file'
        fFileId:form_file_name
        action: opts.action

    r.post '/', upload.single(form_file_name), (req, res) ->
      key = req.body.key?.trim()
      file = req.file

      unless file
        return res.render 'error', msg:'No file provided'

      if key isnt upload_key
        fs.unlink file.path, logger.errNonNil
        logger.warn 'wrong key: ' + key
        res.render 'error', msg:'Wrong key'
      else
        update_file_map file.filename, name:file.originalname, src:req.ip
        logger.info 'file uploaded: ' + file.originalname + ' @ ' + file.path
        res.render 'success', msg:'Uploaded'
    ret null, r
