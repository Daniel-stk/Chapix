(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof exports === 'object') {
    module.exports = factory();
  } else {
    root.palette = factory();
  }
})(this, function() {
  // avoid using lodash in dependencies
  function keys(obj) {
    var keys, key;
    
    keys = [];
    
    for (var key in obj) if (obj.hasOwnProperty(key)) {
      keys.push(key);
    }
    
    return keys;
  }
  
  // avoid using lodash in dependencies
  function random(min, max) {
    return Math.floor(Math.random() * ( max - min + 1 )) + min;
  }

  function rgb2hex(rgb) {
    if (rgb.search("rgb") == -1) {
        return rgb;
    } else {
        rgb = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+))?\)$/);

        function hex(x) {
            return ("0" + parseInt(x).toString(16)).slice(-2);
        }
        return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
    }
  }

  return {
    palette: { 
      'Red': { 
        '50': {
            value : '#FFEBEE',
            bg : 'red lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#FFCDD2',
            bg : 'red lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#EF9A9A',
            bg : 'red lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#E57373',
            bg : 'red lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': {
            value : '#EF5350',
            bg : 'red lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': {
            value : '#F44336',
            bg : 'red',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': {
            value : '#E53935',
            bg : 'red darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': {
            value : '#D32F2F',
            bg : 'red darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': {
            value : '#C62828',
            bg : 'red darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': {
            value : '#B71C1C',
            bg : 'red darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': {
            value : '#FF8A80',
            bg : 'red accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#FF5252',
            bg : 'red accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A400': { 
            value : '#FF1744',
            bg : 'red accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#D50000',
            bg : 'red accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
      },

      'Pink': { 
        '50': {
            value : '#FCE4EC',
            bg : 'pink lighten-5', 
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#F8BBD0',
            bg : 'pink lighten-4',
            txt : '#000000',
            txtName : 'black-text'
         }, 
        '200': { 
            value : '#F48FB1',
            bg : 'pink lighten-3',
            txt : '#000000',
            txtName : 'black-text'
         }, 
        '300': { 
            value : '#F06292',
            bg : 'pink lighten-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
         }, 
        '400': { 
            value : '#EC407A',
            bg : 'pink lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
         }, 
        '500': { 
            value : '#E91E63',
            bg : 'pink',
            txt : '#FFFFFF',
            txtName : 'white-text'
         }, 
        '600': { 
            value : '#D81B60',
            bg : 'pink darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
         }, 
        '700': { 
            value : '#C2185B',
            bg : 'pink darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
         }, 
        '800': { 
            value : '#AD1457',
            bg : 'pink darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        '900': { 
            value : '#880E4F',
            bg : 'pink darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
         },  
        'A100': { 
            value : '#FF80AB',
            bg : 'pink accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#FF4081',
            bg : ' pink accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A400': { 
            value : '#F50057',
            bg : 'pink accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#C51162',
            bg : 'pink accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Purple': { 
        '50': {
            value : '#F3E5F5',
            bg : 'purple lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#E1BEE7',
            bg : 'purple lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#CE93D8',
            bg : 'purple lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#BA68C8',
            bg : 'purple lighten-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '400': { 
            value : '#AB47BC',
            bg : 'purple lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': { 
            value : '#9C27B0',
            bg : 'purple',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#8E24AA',
            bg : 'purple darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#7B1FA2',
            bg : 'purple darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#6A1B9A',
            bg : 'purple darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#4A148C',
            bg : 'purple darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#EA80FC',
            bg : 'purple accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#E040FB',
            bg : 'purple accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A400': { 
            value : '#D500F9',
            bg : 'purple accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#AA00FF',
            bg : 'purple accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Deep Purple': { 
        '50': {
            value : '#EDE7F6',
            bg : 'deep-purple lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#D1C4E9',
            bg : 'deep-purple lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#B39DDB',
            bg : 'deep-purple lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#9575CD',
            bg : 'deep-purple lighten-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '400': { 
            value : '#7E57C2',
            bg : 'deep-purple lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': { 
            value : '#673AB7',
            bg : 'deep-purple',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#5E35B1',
            bg : 'deep-purple darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#512DA8',
            bg : 'deep-purple darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#4527A0',
            bg : 'deep-purple darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#311B92',
            bg : 'deep-purple darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#B388FF',
            bg : 'deep-purple accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#7C4DFF',
            bg : 'deep-purple accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        'A400': { 
            value : '#651FFF',
            bg : 'deep-purple accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#6200EA',
            bg : 'deep-purple accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Indigo': { 
        '50': {
            value :  '#E8EAF6',
            bg : 'indigo lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#C5CAE9',
            bg : 'indigo lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#9FA8DA',
            bg : 'indigo lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#7986CB',
            bg : 'indigo lighten-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '400': { 
            value : '#5C6BC0',
            bg : 'indigo lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': { 
            value : '#3F51B5',
            bg : 'indigo',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#3949AB',
            bg : 'indigo  darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#303F9F',
            bg : 'indigo darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#283593',
            bg : 'indigo darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#1A237E',
            bg : 'indigo darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#8C9EFF',
            bg : 'indigo accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#536DFE',
            bg : 'indigo accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A400': { 
            value : '#3D5AFE',
            bg : 'indigo accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#304FFE',
            bg : 'indigo accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Blue': { 
        '50': {
            value : '#E3F2FD',
            bg : 'blue lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#BBDEFB',
            bg : 'blue lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#90CAF9',
            bg : 'blue lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#64B5F6',
            bg : 'blue lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#42A5F5',
            bg : 'blue lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': { 
            value : '#2196F3',
            bg : 'blue',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#1E88E5',
            bg : 'blue darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#1976D2',
            bg : 'blue darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#1565C0',
            bg : 'blue darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#0D47A1',
            bg : 'blue darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#82B1FF',
            bg : 'blue accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#448AFF',
            bg : 'blue accent-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A400': { 
            value : '#2979FF',
            bg : 'blue accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value : '#2962FF',
            bg : 'blue accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Light Blue': { 
        '50': {
            value : '#E1F5FE',
            bg : 'light-blue lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#B3E5FC',
            bg : 'light-blue lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#81D4FA',
            bg : 'light-blue lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#4FC3F7',
            bg : 'light-blue lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#29B6F6',
            bg : 'light-blue lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': { 
            value : '#03A9F4',
            bg : 'light-blue',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': { 
            value : '#039BE5',
            bg : 'light-blue darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#0288D1',
            bg : 'light-blue darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#0277BD',
            bg : 'light-blue darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#01579B',
            bg : 'light-blue darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#80D8FF',
            bg : 'light-blue accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#40C4FF',
            bg : 'light-blue accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#00B0FF',
            bg : 'light-blue accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#0091EA',
            bg : 'light-blue accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Cyan': { 
        '50': {
            value : '#E0F7FA',
            bg : 'cyan lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#B2EBF2',
            bg : 'cyan lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#80DEEA',
            bg : 'cyan lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#4DD0E1',
            bg : 'cyan lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#26C6DA',
            bg : 'cyan lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': { 
            value : '#00BCD4',
            bg : 'cyan',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': { 
            value : '#00ACC1',
            bg : 'cyan darken-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '700': { 
            value : '#0097A7',
            bg : 'cyan darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#00838F',
            bg : 'cyan darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#006064',
            bg : 'cyan darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#84FFFF',
            bg : 'cyan accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#18FFFF',
            bg : 'cyan accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#00E5FF',
            bg : 'cyan accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#00B8D4',
            bg : 'cyan accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Teal': { 
        '50': {
            value : '#E0F2F1',
            bg : 'teal lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#B2DFDB',
            bg : 'teal lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#80CBC4',
            bg : 'teal lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#4DB6AC',
            bg : 'teal lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#26A69A',
            bg : 'teal lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': { 
            value : '#009688',
            bg : 'teal',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#00897B',
            bg : 'teal darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#00796B',
            bg : 'teal darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#00695C',
            bg : 'teal darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#004D40',
            bg : 'teal darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': {
            value : '#A7FFEB',
            bg : 'teal accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': {
            value : '#64FFDA',
            bg : 'teal accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': {
            value : '#1DE9B6',
            bg : 'teal accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': {
            value : '#00BFA5',
            bg : 'teal accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Green': { 
        '50': {
            value : '#E8F5E9',
            bg : 'green lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#C8E6C9',
            bg : 'green lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#A5D6A7',
            bg : 'green lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#81C784',
            bg : 'green lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#66BB6A',
            bg : 'green lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': { 
            value : '#4CAF50',
            bg : 'green',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': { 
            value : '#43A047',
            bg : 'green darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#388E3C',
            bg : 'green darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#2E7D32',
            bg : 'green darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#1B5E20',
            bg : 'green darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#B9F6CA',
            bg : 'green accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#69F0AE',
            bg : 'green accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#00E676',
            bg : 'green accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#00C853',
            bg : 'green accent-4',
            txt : '#000000',
            txtName : 'black-text'
        }
      },

      'Light Green': { 
        '50': {
            value : '#F1F8E9',
            bg : 'light-green lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#DCEDC8',
            bg : 'light-green lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#C5E1A5',
            bg : 'light-green lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#AED581',
            bg : 'light-green lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': {
            value : '#9CCC65',
            bg : 'light-green lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': {
            value : '#8BC34A',
            bg : 'light-green',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': {
            value : '#7CB342',
            bg : 'light-green darken-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '700': {
            value : '#689F38',
            bg : 'light-green darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': {
            value : '#558B2F',
            bg : 'light-green darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': {
            value : '#33691E',
            bg : 'light-green darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#CCFF90',
            bg : 'light-green accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#B2FF59',
            bg : 'light-green accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#76FF03',
            bg : 'light-green accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#64DD17',
            bg : 'light-green accent4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Lime': { 
        '50': {
            value : '#F9FBE7',
            bg : 'lime lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#F0F4C3',
            bg : 'lime lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#E6EE9C',
            bg : 'lime lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#DCE775',
            bg : 'lime lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': {
            value : '#D4E157',
            bg : 'lime lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': {
            value : '#CDDC39',
            bg : 'lime',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': {
            value : '#C0CA33',
            bg : 'lime darken-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '700': {
            value : '#AFB42B',
            bg : 'lime darken-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '800': {
            value : '#9E9D24',
            bg : 'lime darken-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '900': {
            value : '#827717',
            bg : 'lime darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A100': { 
            value : '#F4FF81',
            bg : 'lime accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#EEFF41',
            bg : 'lime accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#C6FF00',
            bg : 'lime accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#AEEA00',
            bg : 'lime accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Yellow': { 
        '50': {
            value : '#FFFDE7',
            bg : 'yellow lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#FFF9C4',
            bg : 'yellow lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#FFF59D',
            bg : 'yellow lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#FFF176',
            bg : 'yellow lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': {
            value : '#FFEE58',
            bg : 'yellow lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': {
            value : '#FFEB3B',
            bg : 'yellow',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': {
            value : '#FDD835',
            bg : 'yellow darken-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '700': {
            value : '#FBC02D',
            bg : 'yellow darken-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '800': {
            value : '#F9A825',
            bg : 'yellow darken-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '900': {
            value : '#F57F17',
            bg : 'yellow darken-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A100': { 
            value : '#FFFF8D',
            bg : 'yellow accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value : '#FFFF00',
            bg : 'yellow accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value : '#FFEA00',
            bg : 'yellow accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value : '#FFD600',
            bg : 'yellow accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Amber': { 
        '50': {
            value : '#FFF8E1',
            bg : 'amber lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#FFECB3',
            bg : 'amber lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#FFE082',
            bg : 'amber lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#FFD54F',
            bg : 'amber lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#FFCA28',
            bg : 'amber lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': { 
            value : '#FFC107',
            bg : 'amber',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': { 
            value : '#FFB300',
            bg : 'amber darken-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '700': { 
            value : '#FFA000',
            bg : 'amber darken-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '800': { 
            value : '#FF8F00',
            bg : 'amber darken-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '900': { 
            value : '#FF6F00',
            bg : 'amber darken-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A100': {
            value : '#FFE57F',
            bg : 'amber accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': {
            value : '#FFD740',
            bg : 'amber accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': {
            value : '#FFC400',
            bg : 'amber accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': {
            value : '#FFAB00',
            bg : 'amber accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Orange': { 
        '50':   { 
            value : '#FFF3E0', 
            bg : 'orange lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        },
        '100':  { 
            value : '#FFE0B2', 
            bg : 'orange lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        },
        '200':  { 
            value : '#FFCC80', 
            bg : 'orange lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        },
        '300':  { 
            value : '#FFB74D',
            bg : 'orange lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        },
        '400':  { 
            value : '#FFA726', 
            bg : 'orange lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        },
        '500':  { 
            value : '#FF9800', 
            bg : 'orange',
            txt : '#000000',
            txtName : 'black-text'
        },
        '600':  { 
            value : '#FB8C00', 
            bg : 'orange darken-1',
            txt : '#000000',
            txtName : 'black-text'
        },
        '700':  { 
            value : '#F57C00', 
            bg : 'orange darken-2',
            txt : '#000000',
            txtName : 'black-text'
        },
        '800':  { 
            value : '#EF6C00',
            bg : 'orange darken-3',
            txt : '#FFFFFF' ,
            txtName : 'white-text'
        },
        '900':  { 
            value : '#E65100',
            bg : 'orange darken-4',
            txt : '#FFFFFF' ,
            txtName : 'white-text'
        },
        'A100': { 
            value :  '#FFD180',
            bg : 'orange accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value :  '#FFAB40',
            bg : 'orange accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value :  '#FF9100',
            bg : 'orange accent-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A700': { 
            value :  '#FF6D00',
            bg : 'orange accent-4',
            txt : '#000000',
            txtName : 'black-text'
        } 
      },

      'Deep Orange': { 
        '50':   { 
            value : '#FBE9E7', 
            bg : 'deep-orange lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        },
        '100':  { 
            value : '#FFCCBC', 
            bg : 'deep-orange lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        },
        '200':  { 
            value : '#FFAB91', 
            bg : 'deep-orange lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        },
        '300':  { 
            value : '#FF8A65', 
            bg : 'deep-orange lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        },
        '400':  { 
            value : '#FF7043', 
            bg : 'deep-orange lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        },
        '500':  { 
            value : '#FF5722',
            bg : 'deep-orange',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        '600':  { 
            value : '#F4511E', 
            bg : 'deep-orange darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        '700':  { 
            value : '#E64A19', 
            bg : 'deep-orange darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        '800':  { 
            value : '#D84315',
            bg : 'deep-orange darken-3',
            txt : '#FFFFFF' ,
            txtName : 'white-text'
        },
        '900':  { 
            value : '#BF360C', 
            bg : 'deep-orange darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        },
        'A100': { 
            value :  '#FF9E80',
            bg : 'deep-orange accent-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A200': { 
            value :  '#FF6E40',
            bg : 'deep-orange accent-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        'A400': { 
            value :  '#FF3D00',
            bg : 'deep-orange accent-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        'A700': { 
            value :  '#DD2C00',
            bg : 'deep-orange accent-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Brown': { 
        '50':  {
            value : '#EFEBE9',
            bg : 'brown lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#D7CCC8',
            bg : 'brown lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#BCAAA4',
            bg : 'brown lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#A1887F',
            bg : 'brown lighten-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '400': {
            value : '#8D6E63',
            bg : 'brown lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': {
            value : '#795548',
            bg : 'brown',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': {
            value : '#6D4C41',
            bg : 'brown darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': {
            value : '#5D4037',
            bg : 'brown darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': {
            value : '#4E342E',
            bg : 'brown darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': {
            value : '#3E2723',
            bg : 'brown darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
      },

      'Grey': { 
        '50':  {
            value : '#FAFAFA',
            bg : 'grey lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': {
            value : '#F5F5F5',
            bg : 'grey lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': {
            value : '#EEEEEE',
            bg : 'grey lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': {
            value : '#E0E0E0',
            bg : 'grey lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': {
            value : '#BDBDBD',
            bg : 'grey lighten-1',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '500': {
            value : '#9E9E9E',
            bg : 'grey',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '600': {
            value : '#757575',
            bg : 'grey darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': {
            value : '#616161',
            bg : 'grey darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': {
            value : '#424242',
            bg : 'grey darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': {
            value : '#212121',
            bg : 'grey darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Blue Grey': { 
        '50':  { 
            value : '#ECEFF1',
            bg : 'blue-grey lighten-5',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '100': { 
            value : '#CFD8DC',
            bg : 'blue-grey lighten-4',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '200': { 
            value : '#B0BEC5',
            bg : 'blue-grey lighten-3',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '300': { 
            value : '#90A4AE',
            bg : 'blue-grey lighten-2',
            txt : '#000000',
            txtName : 'black-text'
        }, 
        '400': { 
            value : '#78909C',
            bg : 'blue-grey lighten-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '500': { 
            value : '#607D8B',
            bg : 'blue-grey',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '600': { 
            value : '#546E7A',
            bg : 'blue-grey darken-1',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '700': { 
            value : '#455A64',
            bg : 'blue-grey darken-2',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '800': { 
            value : '#37474F',
            bg : 'blue-grey darken-3',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }, 
        '900': { 
            value : '#263238',
            bg : 'blue-grey darken-4',
            txt : '#FFFFFF',
            txtName : 'white-text'
        } 
      },

      'Black': { 
        '500': {
            value : '#000000',
            bg : 'black',
            txt : '#FFFFFF',
            txtName : 'white-text'
        }
      },

      'White': { 
        '500': {
            value : '#FFFFFF',
            bg : 'white',
            txt : '#000000',
            txtName : 'black-text'
        }
      },
    },

    get: function (color, shade) {        
      // console.log( color, shade);
      return this.palette[color][shade || '500']['value'];
    },

    getAllPalette : function (){
        var palette = [];
        $.each(this.palette, function(key, data){
            var colorarray = [];
            $.each(data, function(index, value){
                colorarray.push(value.value)
            });
            if (colorarray.length) palette.push(colorarray);
        });
        return palette;
    },

    getAccentPalette : function (){
        var palette = [];
        $.each(this.palette, function(key, data){
           var colorArray = [];
           $.each(data, function(index, value){
               if (index.match(/^A[0-9]/) && typeof value.value != undefined && typeof value.value != false) colorArray.push(value.value)
           });
           if (colorArray.length) palette.push(colorArray);
        });
        return palette;
    },

    getPrimaryPalette : function (){
        var palette = [];
        $.each(this.palette, function(key, data){
           var colorArray = [];
           $.each(data, function(index, value){
               if (!index.match(/^A[0-9]/) && typeof value.value != undefined && typeof value.value != false) colorArray.push( value.value )
           });
           if (colorArray.length) palette.push(colorArray);
        });
        return palette;
    },

    random: function(shade) {
      var colors, color, shades;
    
      colors = keys(this.palette);      
      color = colors[random(0, colors.length - 1)];


      if (shade == null || shade == '') {
        shades = keys(color);
        shade = shades[random(0, shades.length - 1)];
      }
      return this.get(color, shade);
    },

    getBgName : function (color) {    
    color = rgb2hex(color);
    var name = '';
    $.each( this.palette, function(key, data){
        $.each(data, function(index, value){
            if (value.value == color.toString().toUpperCase()) name = value.bg
        });        
    });
    return name;
    },

    getTxtColor : function(color){
    color = rgb2hex(color);
    var name = '';
    $.each( this.palette, function(key, data){
        $.each(data, function(index, value){
            if (value.value == color.toUpperCase()) name = value.txt
        });        
    });
    return name;
    },

    getTxtColorName : function(color){  
    var name = '';
    $.each( this.palette, function(key, data){
        $.each(data, function(index, value){
            if (value.value == color.toString().toUpperCase()) name = value.txtName
        });        
    });
    return name;
    }

  };
});