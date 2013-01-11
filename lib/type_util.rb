# -*- encoding: utf-8 -*-
module TypeUtil
  $TYPES = nil
  $TYPE_CONDITIONS = nil

  def TypeUtil.initTypes
    yaml_file = File.join(Rails.root,'config','types.yml')
    if File.exist?(yaml_file)
      TypeUtil.setTypes_offline(yaml_file)
    else
      TypeUtil.setTypes
    end
  end

  # 名称マスタの初期読み込み
  # $TYPES[:type_section][:type_key]で名称にアクセスできる
  def TypeUtil.setTypes
    types = Type.find(:all, :conditions => "deleted = 0 ", :order => " type_section, display_order1")
    $TYPES = Hash.new
    $TYPE_CONDITIONS = Hash.new
    types.each {|x|
      $TYPES[x.type_section] = Hash.new if $TYPES[x.type_section].nil?
      $TYPES[x.type_section][x.type_key] = x
      $TYPE_CONDITIONS[x.type_section] = Array.new if $TYPE_CONDITIONS[x.type_section].nil?
      $TYPE_CONDITIONS[x.type_section].push [x.long_name, x.type_key]
    }
  end
  
  def TypeUtil.setTypes_offline(yaml_file)
    yaml = YAML.load_file(yaml_file)
    $TYPES = Hash.new
    $TYPE_CONDITIONS = Hash.new
    yaml.each{|key,val|
      val.delete('id')
      x = Type.new(val)
      $TYPES[x.type_section] = Hash.new if $TYPES[x.type_section].nil?
      $TYPES[x.type_section][x.type_key] = x
      $TYPE_CONDITIONS[x.type_section] = Array.new if $TYPE_CONDITIONS[x.type_section].nil?
      $TYPE_CONDITIONS[x.type_section].push [x.long_name, x.type_key]
    }
  end

  # キャッシュデータの初期化
  initTypes unless $TYPES

  def getTypeConditions(section)
    TypeUtil.getTypeConditions(section)
  end

  def TypeUtil.getTypeConditions(section)
    $TYPE_CONDITIONS[section] || []
  end

  def TypeUtil.getTypes(section)
    $TYPES[section] || {}
  end
  
  # 名称オブジェクトを取得
  def getTypeObject(section, key)
    TypeUtil.getTypeObject(section, key)
  end

  def TypeUtil.getTypeObject(section, key)
    x = TypeUtil.getTypes(section.to_s)
    x[key.to_s]
  end

  # 区分名称を取得
  def getLongType(section, key, unknown = "Unknown type")
    TypeUtil.getLongType(section, key, unknown)
  end

  def TypeUtil.getLongType(section, key, unknown = "Unknown type")
    return unknown + "(#{key})" if key.blank?
    type = TypeUtil.getTypeObject(section, key)
    type.blank? ? unknown + "(#{key})" : type.long_name
  end

  # 区分略称を取得
  def getShortType(section, key)
    return '' if key.blank?
    if $TYPES[section.to_s].nil?
      "Unknown type(#{key})"
    else
      type = $TYPES[section.to_s][key.to_s]
      type.nil? ? "Unknown type(#{key})" : type.short_name
    end
  end

  # 区分その他の名前を取得
  def getOtherType(section, key)
    return '' if key.blank?
    if $TYPES[section.to_s].nil?
      "Unknown type(#{key})"
    else
      type = $TYPES[section.to_s][key.to_s]
      type.nil? ? "Unknown type(#{key})" : type.other_name
    end
  end

end
