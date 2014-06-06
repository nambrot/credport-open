# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# credportapp = Application.find_by_name(:credport)
# credport_application_context = EntityContext.find_by_name(:credport_application_context)

# verbprotocol = ConnectionContextProtocol.find_by_name('verb-protocol')
# textprotocol = ConnectionContextProtocol.find_by_name('text-protocol')
# relationshipprotocol = ConnectionContextProtocol.find_by_name('relationship-protocol')


credportapp = Application.create! :name => 'credport', :redirect_uri => 'https://www.credport.org'
credport_application_context = EntityContext.create! :name => 'credport_application_context', :title => "Credport Application", :application => credportapp
credport_entity_context = EntityContext.create! :name => 'credport_entity_context', :title => "Credport Entity", :application => credportapp
credport_work_context = EntityContext.create! :name => 'credport_workplace_context', :title => "Credport Workplace" ,  :application => credportapp
credportentity = Entity.create!({
  :name => 'Credport',
  :url => "https://www.credport.org",
  :image => "https://www.credport.org/favicon.ico",
  :context => credport_application_context,
  :uid => 'credport_entity'
  })
credportapp.entity = credportentity
credportapp.save


Entity.create!({
  :uid => 'Anonymous_School',
  :context => credport_entity_context,
  :name => 'Anonymous School',
  :url => "http://www.credport.org",
  :image => 'https://s3.amazonaws.com/credport-assets/assets/anonymous_school.png'
})

Entity.create!({
  :uid => 'Anonymous_Workplace',
  :context => credport_entity_context,
  :name => 'Anonymous Workplace',
  :url => "http://www.credport.org",
  :image => 'https://s3.amazonaws.com/credport-assets/assets/anonymous_work.png'
})

# ConnectionContextProtocols
idprotocol = ConnectionContextProtocol.create!({
  :name => 'id-protocol',
  :attribute_constraints => {
    :id => {
      :presence => true,
      :type => 'string'
    } 
  },
  :context_constraints => {}
  })
textprotocol = ConnectionContextProtocol.create!({
    :name => 'text-protocol',
    :attribute_constraints => {
      :text => {
        :presence => true,
        :type => 'string'
      }
    },
    :context_constraints => {}
  })
relationshipprotocol = ConnectionContextProtocol.create!({
  :name => 'relationship-protocol',
  :attribute_constraints => {},
  :context_constraints => {
    :relationship => {
      :presence => true,
      :type => 'hash',
      :format => {
        :sourcerole => {
          :presence => true,
          :type => 'string'
          },
        :sinkrole => {
          :presence => true,
          :type => 'string'
        }
      }
    }
  }
  })
verbprotocol = ConnectionContextProtocol.create!({
  :name => 'verb-protocol',
  :attribute_constraints => {},
  :context_constraints => {
    :verbs => {
      :presence => true,
      :type => 'hash',
      :format => {
        :forward => {
          :presence => true,
          :type => 'string'
        },
        :backward => {
          :presence => true,
          :type => 'string'
        },
        :common_connection => {
          :presence => true,
          :type => 'string'
        },
        :common_interest => {
          :presence => true,
          :type => 'string'
        }
      }
    }
  }
  })

facebookentity = Entity.create!({
  :name => "Facebook",
  :url => "https://www.facebook.com",
  :image => "https://s3.amazonaws.com/credport-assets/assets/icon_fb.png",
  :context => credport_application_context,
  :uid => 'facebook_app_entity'
  })
facebookapp = Application.create! :name => 'facebook', :entity => facebookentity, :redirect_uri => 'https://www.facebook.com'

facebook_identity_context = IdentityContext.create! :name => 'facebook', :application => facebookapp, :title => "Facebook Profile"

facebook_entity_context = EntityContext.create! :name => "facebook", :application => facebookapp, :title => 'Facebook Object'

twitterentity = Entity.create!({
  :name => "Twitter",
  :url => "https://www.twitter.com",
  :image => "https://s3.amazonaws.com/credport-assets/assets/icon_twitter.png",
  :context => credport_application_context,
  :uid => 'twitter_app_entity'
  })
twitterapp = Application.create! :name => 'twitter', :entity => twitterentity, :redirect_uri => 'https://www.twitter.com'

facebook_identity_context = IdentityContext.create! :name => 'twitter', :application => twitterapp, :title => "Twitter Profile"


linkedinentity = Entity.create!({
  :uid => 'linkedin_app_entity',
  :context => credport_application_context,
  :name => 'LinkedIn',
  :url => 'http://www.linkedin.com',
  :image => 'https://s3.amazonaws.com/credport-assets/assets/icon_linkedin.png'
})  
linkedinapp = Application.create! :name => "linkedin", :entity => linkedinentity, :redirect_uri => 'https://www.linkedin.com'
linkedin_identity_context = IdentityContext.create! :name => 'linkedin', :application => linkedinapp, :title => "LinkedIn Profile"
linkedin_entity_context = EntityContext.create! :name => "linkedin", :application => linkedinapp, :title => 'LinkedIn Object'

Identity.create!({
  :uid => 'anonymous-linkedin-user-credport',
  :context => linkedin_identity_context,
  :name => 'Anonymous LinkedIn User',
  :image => 'https://s3.amazonaws.com/credport-assets/assets/icon_linkedin.png',
  :url => 'http://www.linkedin.com/'
  })

ebayentity = Entity.create!({
  :uid => 'ebay_app_entity',
  :context => credport_application_context,
  :name => 'Ebay',
  :url => 'http://www.ebay.com/',
  :image => 'https://s3.amazonaws.com/credport-assets/assets/icon_ebay.png',
})

ebayapp = Application.create! :name => 'ebay' , 
                              :entity => ebayentity, 
                              :redirect_uri=> "http://www.ebay.com" 

ebay_identity_context = IdentityContext.create! :name => "ebay",
                                            :application => ebayapp,
                                            :title => "Ebay Profile"

ebay_entity_context = EntityContext.create! :name => "ebay" , 
                                            :application => ebayapp, 
                                            :title => 'Ebay Object'

Identity.create!({
  :uid => 'anonymous-ebay-user-credport',
  :context => ebay_identity_context,
  :name => 'Anonymous Ebay User',
  :image => 'https://s3.amazonaws.com/credport-assets/assets/icon_ebay.png',
  :url => 'http://www.ebay.com'
})

facebook_like_context = ConnectionContext.create!({
  :name => "facebook-like",
  :cardinality => '1',
  :connection_type => "identity-entity",
  :application => facebookapp,
  :async => true,
  :properties => {
    :verbs => {
       :forward => 'likes',
       :backward => "is liked by",
       :common_connection => 'are connected via',
       :common_interest => 'both like'
     },
     :relationship => {
       :sourcerole => 'liker',
       :sinkrole => 'liked entity'
     }
  }
  })
facebook_like_context.connection_context_protocols << verbprotocol
facebook_like_context.connection_context_protocols << relationshipprotocol

facebook_friend_context = ConnectionContext.create!({
  :name => "facebook-friendship",
  :cardinality => '1',
  :connection_type => "identity-identity",
  :application => facebookapp,
  :async => false,
  :properties => {
    :verbs => {
      :forward => 'is friends with',
      :backward => "is friends with",
      :common_connection => 'are both friends with',
      :common_interest => 'are both friends with'
    },
    :relationship => {
      :sourcerole => 'friend',
      :sinkrole => 'friend'
    }
  }
  })
facebook_friend_context.connection_context_protocols << verbprotocol
facebook_friend_context.connection_context_protocols << relationshipprotocol

twitterfollowership = ConnectionContext.create!({
  :name => "twitter-followership",
  :cardinality => '1',
  :connection_type => "identity-identity",
  :application => twitterapp,
  :async => true,
  :properties => {
    :verbs => {
      :forward => 'follows',
      :backward => "is followed by",
      :common_connection => 'are connected via',
      :common_interest => 'both follow'
    },
    :relationship => {
      :sourcerole => 'follower',
      :sinkrole => 'followee'
    }
  }
  })
twitterfollowership.connection_context_protocols << verbprotocol
twitterfollowership.connection_context_protocols << relationshipprotocol

linkedin_connection_context = ConnectionContext.create!({
  :name => 'linkedin-connection',
  :async => false,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => linkedinapp,
  :properties => {
    :verbs => {
      :forward => 'is connected with',
      :backward => "is connected with",
      :common_connection => 'are both connected with',
      :common_interest => 'are both connected with'
    },
    :relationship => {
      :sourcerole => 'connection',
      :sinkrole => 'connection'
    }
  }
})
linkedin_connection_context.connection_context_protocols << verbprotocol
linkedin_connection_context.connection_context_protocols << relationshipprotocol

linkedinrecommendationbp = ConnectionContext.create!({
  :name => 'linkedinrecommendation-bp',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => linkedinapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'is recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'recommender',
      :sinkrole => 'recommendee'
    }
  }
})
linkedinrecommendationbp.connection_context_protocols << textprotocol
linkedinrecommendationbp.connection_context_protocols << verbprotocol
linkedinrecommendationbp.connection_context_protocols << relationshipprotocol
linkedinrecommendationbp.connection_context_protocols << idprotocol

linkedinrecommendationcolleague = ConnectionContext.create!({
  :name => 'linkedinrecommendation-colleague',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => linkedinapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'is recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'recommender',
      :sinkrole => 'recommendee'
    }
  }
})
linkedinrecommendationcolleague.connection_context_protocols << textprotocol
linkedinrecommendationcolleague.connection_context_protocols << verbprotocol
linkedinrecommendationcolleague.connection_context_protocols << relationshipprotocol
linkedinrecommendationcolleague.connection_context_protocols << idprotocol

linkedinrecommendationeducation = ConnectionContext.create!({
  :name => 'linkedinrecommendation-education',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => linkedinapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'is recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'recommender',
      :sinkrole => 'recommendee'
    }
  }
})
linkedinrecommendationeducation.connection_context_protocols << textprotocol
linkedinrecommendationeducation.connection_context_protocols << verbprotocol
linkedinrecommendationeducation.connection_context_protocols << relationshipprotocol
linkedinrecommendationeducation.connection_context_protocols << idprotocol

linkedinrecommendationsp = ConnectionContext.create!({
  :name => 'linkedinrecommendation-sp',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => linkedinapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'is recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'recommender',
      :sinkrole => 'recommendee'
    }
  }
})
linkedinrecommendationsp.connection_context_protocols << textprotocol
linkedinrecommendationsp.connection_context_protocols << verbprotocol
linkedinrecommendationsp.connection_context_protocols << relationshipprotocol
linkedinrecommendationsp.connection_context_protocols << idprotocol

ebaybuyerfeedback = ConnectionContext.create!({
  :name => 'ebayfeedback-buyer',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => ebayapp,
  :properties => {
    :verbs => {
      :forward => 'sold to',
      :backward => 'bought from',
      :common_connection => 'had a transaction with',
      :common_interest => 'had a transaction with'
    },
    :relationship => {
      :sourcerole => 'seller',
      :sinkrole => 'buyer'
    }
  }
})

ebaybuyerfeedback.connection_context_protocols << textprotocol 
ebaybuyerfeedback.connection_context_protocols << verbprotocol
ebaybuyerfeedback.connection_context_protocols << relationshipprotocol  
ebaybuyerfeedback.connection_context_protocols << idprotocol

ebaysellerfeedback = ConnectionContext.create!({
  :name => 'ebayfeedback-seller',
  :async => true,
  :cardinality => 'id1',
  :connection_type => "identity-identity",
  :application => ebayapp,
  :properties => {
    :verbs => {
      :forward => 'boughtfrom',
      :backward => 'sold to',
      :common_connection => 'had a transaction with',
      :common_interest => 'had a transaction with'
    },
    :relationship => {
      :sourcerole => 'buyer',
      :sinkrole => 'seller'
    }
  }
})

ebaysellerfeedback.connection_context_protocols << textprotocol
ebaysellerfeedback.connection_context_protocols << verbprotocol
ebaysellerfeedback.connection_context_protocols << relationshipprotocol 
ebaysellerfeedback.connection_context_protocols << idprotocol

# Paypal stuff Feb 1st 2013

paypalentity = Entity.create!({
  :name => "PayPal",
  :url => "https://www.paypal.com",
  :image => "https://s3.amazonaws.com/credport-assets/assets/icon_paypal.png",
  :context => credport_application_context,
  :uid => 'paypal_app_entity'
  })
paypalapp = Application.create! :name => 'paypal', :entity => paypalentity, :redirect_uri => 'https://www.paypal.com'

paypal_identity_context = IdentityContext.create! :name => 'paypal', :application => paypalapp, :title => "PayPal Account"

# recommendation add from 15 Feb 2013
credport_identity_context = IdentityContext.create! :name => "credport",
                                            :application => credportapp,
                                            :title => "Credport Profile"
credport_friend_recommendation_context = ConnectionContext.create!({
  :name => 'credport_friend_recommendation',
  :async => true,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => credportapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'was recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'friend',
      :sinkrole => 'friend'
    }
  }
  })
credport_friend_recommendation_context.connection_context_protocols << textprotocol
credport_friend_recommendation_context.connection_context_protocols << verbprotocol
credport_friend_recommendation_context.connection_context_protocols << relationshipprotocol 

credport_colleague_recommendation_context = ConnectionContext.create!({
  :name => 'credport_colleague_recommendation',
  :async => true,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => credportapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'was recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'colleague',
      :sinkrole => 'colleague'
    }
  }
  })
credport_colleague_recommendation_context.connection_context_protocols << textprotocol
credport_colleague_recommendation_context.connection_context_protocols << verbprotocol
credport_colleague_recommendation_context.connection_context_protocols << relationshipprotocol 

credport_family_recommendation_context = ConnectionContext.create!({
  :name => 'credport_family_recommendation',
  :async => true,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => credportapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'was recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'family member',
      :sinkrole => 'familiy member'
    }
  }
  })

credport_family_recommendation_context.connection_context_protocols << textprotocol
credport_family_recommendation_context.connection_context_protocols << verbprotocol
credport_family_recommendation_context.connection_context_protocols << relationshipprotocol 
credport_other_recommendation_context = ConnectionContext.create!({
  :name => 'credport_other_recommendation',
  :async => true,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => credportapp,
  :properties => {
    :verbs => {
      :forward => 'recommends',
      :backward => 'was recommended by',
      :common_connection => 'are connected via',
      :common_interest => 'both recommend'
    },
    :relationship => {
      :sourcerole => 'unspecified',
      :sinkrole => 'unspecified'
    }
  }
  })
credport_other_recommendation_context.connection_context_protocols << textprotocol
credport_other_recommendation_context.connection_context_protocols << verbprotocol
credport_other_recommendation_context.connection_context_protocols << relationshipprotocol 

xingentity = Entity.create!({
  :name => "Xing",
  :url => "https://www.xing.com",
  :image => "https://s3.amazonaws.com/credport-assets/assets/icon_xing.png",
  :context => credport_application_context,
  :uid => 'xing_app_entity'
  })
xingapp = Application.create! :name => 'xing', :entity => xingentity, :redirect_uri => 'https://www.xing.com'

xing_identity_context = IdentityContext.create! :name => 'xing', :application => xingapp, :title => "Xing Profile"

xing_entity_context = EntityContext.create! :name => "xing", :application => xingapp, :title => 'Xing Object'

xing_connection_context = ConnectionContext.create!({
  :name => 'xing-connection',
  :async => false,
  :cardinality => '1',
  :connection_type => 'identity-identity',
  :application => xingapp,
  :properties => {
    :verbs => {
      :forward => 'is connected with',
      :backward => "is connected with",
      :common_connection => 'are both connected with',
      :common_interest => 'are both connected with'
    },
    :relationship => {
      :sourcerole => 'connection',
      :sinkrole => 'connection'
    }
  }
})
xing_connection_context.connection_context_protocols << verbprotocol
xing_connection_context.connection_context_protocols << relationshipprotocol

