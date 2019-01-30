<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="SkinSettings.ascx.vb" Inherits="Intelledox.Manage.SkinSettings" ClassName="Global.Intelledox.Manage.SkinSettings" %>
<script src="Scripts/jqColorPicker.min.js" type="text/javascript"></script>
<table class="editsectionsettings">
    <tr>
        <th colspan="4">
            <asp:Label ID="lblLogos" runat="server" />
            <asp:HiddenField ID="resetUrlCtrl" runat="server" />
        </th>
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblSkinLogo" runat="server" AssociatedControlID="fileLogo" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblSkinLogoHelp" runat="server" /></span>
            </div>
        </td>
        <td >
            <span id="spanLogo" runat="server">
                <ul class="enlarge">
                    <li>
                        <asp:Image ID="logoPreviewThumb" runat="server" class="logo" />
                        <span>
                            <asp:Image ID="logoPreview" runat="server" Style="max-width: 385px" /></span>
                    </li>
                </ul>
               
            </span>
        </td>
        <td colspan="2">
            <asp:FileUpload ID="fileLogo" runat="server" Style="width: 200px; padding-top: 4px;" />
        </td>
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblSkinLogoMobile" runat="server" AssociatedControlID="fileMobile" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblSkinLogoMobileHelp" runat="server" /></span>
            </div>
        </td>
        <td>
            <span id="span1" runat="server">
                <asp:Image ID="mobilePreview" runat="server" Style="max-height: 60px; vertical-align: middle" />
                
            </span>
        </td>
        <td colspan="2">
            <asp:FileUpload ID="fileMobile" runat="server" Style="width: 200px; padding-top: 4px;" />
        </td>
        
    </tr>
    <tr>
        <td colspan="4">
            <asp:Button ID="btnRemove" runat="server" CssClass="toolbtn" Style="margin-left: 4px" Visible="False" CausesValidation="false" OnClick="btnRemove_Click" />
        </td>
    </tr>
    </table>
<table class="editsectionsettings">
    <tr>
        <th colspan="2" style="border-right: 1px white solid">
            <asp:Label ID="lblHeader" runat="server" />
        </th>
        <th colspan="2">
            <asp:Label ID="lblColorScheme" runat="server" />
        </th>
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblHeaderBackgroundColor" runat="server" AssociatedControlID="headerBackgroundColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblHeaderBackgroundColorHelp" runat="server" /></span>
            </div>
        </td>
        <td >
            <asp:TextBox ID="headerBackgroundColor" runat="server" CssClass="color" MaxLength="7" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblPrimaryColor" runat="server" AssociatedControlID="primaryColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblPrimaryColorHelp" runat="server" /></span>
            </div>
        </td>
        <td>
            <asp:TextBox ID="primaryColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
       
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblHeaderFontColor" runat="server" AssociatedControlID="headerFontColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblHeaderFontColorHelp" runat="server" /></span>
            </div>
        </td>
        <td >
            <asp:TextBox ID="headerFontColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblSecondaryColor" runat="server" AssociatedControlID="secondaryColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblSecondaryColorHelp" runat="server" /></span>
            </div>
        </td>
        <td >
            <asp:TextBox ID="secondaryColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
       
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblHeaderLinkColor" runat="server" AssociatedControlID="headerLinkColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblHeaderLinkColorHelp" runat="server" /></span>
            </div>
        </td>
        <td >
            <asp:TextBox ID="headerLinkColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblTextLinkColor" runat="server" AssociatedControlID="textLinkColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblTextLinkColorHelp" runat="server" /></span>
            </div>
        </td>
        <td >
        <asp:TextBox ID="textLinkColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
        </asp:TextBox>
        </td>
       
    </tr>
    <tr>
        <td>
            <div style ="display: inline-block"><asp:Label ID="lblHeaderFontHoverColor" runat="server" AssociatedControlID="headerFontHoverColor" /></div>
            <div class ="tooltip">
                <div class="question-svg"></div>
                <span class="tooltiptext"><asp:Label ID="lblHeaderFontHoverColorHelp" runat="server" /></span>
            </div>
        </td>
        <td>
            <asp:TextBox ID="headerFontHoverColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
        <td>
            <%-- Label and field set to not visible here until we incorporate the required field feature fully into the default theme --%>
            <div style ="display: inline-block"><asp:Label ID="lblRequiredFieldBackground" runat="server" AssociatedControlID="RequiredFieldBackground" Visible="false"/></div>
           <%-- <div class ="tooltip">
                <div class="question-svg"></div>--%>
                <span class="tooltiptext" style="display:none"><asp:Label ID="lblRequiredFieldBackgroundHelp" runat="server" Visible="false" /></span>
            <%-- </div>--%>
        </td>
        <td>
            <asp:TextBox ID="RequiredFieldBackground" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" Visible="false" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
            </asp:TextBox>
        </td>
      
    </tr>
    <tr>
        <td colspan="4">&nbsp</td>
    </tr>
   
   </table>

<table class="editsectionsettings">
 
    <asp:Panel ID="pnlMobileColorScheme" Visible="False" runat="server">
        <tr>
            <th colspan="3">
                <asp:Label ID="lblMobileColorScheme" runat="server" />
            </th>
        </tr>
        <tr>
            <td>
                <div style ="display: inline-block"> <asp:Label ID="lblAppBackgroundColor" runat="server" AssociatedControlID="appBackgroundColor" /></div>
                <div class ="tooltip">
                    <div class="question-svg"></div>
                    <span class="tooltiptext"><asp:Label ID="lblAppBackgroundColorHelp" runat="server" /></span>
                </div>
            </td>
            <td colspan="2">
                <asp:TextBox ID="appBackgroundColor" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
                </asp:TextBox>
            </td>
        </tr>
        <asp:Panel ID="pnlProjectIconColors" Visible="True" runat="server">
            <tr>
                <td style="vertical-align: top; padding-top: 5px">
                    <div style ="display: inline-block"><asp:Label ID="lblCircleColors" runat="server" AssociatedControlID="circleColor1" /></div>
                    <div class ="tooltip">
                        <div class="question-svg"></div>
                        <span class="tooltiptext"><asp:Label ID="lblCircleColorsHelp" runat="server" /></span>
                    </div>
                </td>
                <td colspan="2">
                    <div>
                        <asp:TextBox ID="circleColor1" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
                        </asp:TextBox>
                    </div>
                    <div style="padding-top: 3px;">
                        <asp:TextBox ID="circleColor2" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
                        </asp:TextBox>
                    </div>
                    <div style="padding-top: 3px;">
                        <asp:TextBox ID="circleColor3" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
                        </asp:TextBox>
                    </div>
                    <div style="padding-top: 3px;">
                        <asp:TextBox ID="circleColor4" runat="server" CssClass="color" MaxLength="7" ValidateRequestMode="Enabled" type="text" pattern="^#+([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$">
                
                        </asp:TextBox>
                    </div>
                </td>
               
            </tr>
        </asp:Panel>
    </asp:Panel>
    <tr>
        <tr>
            <td colspan="3">&nbsp</td>
        </tr>
    </tr>
    <tr>
        <td colspan="3" style="border: 0">
            <asp:Label runat="server" ID ="lblExampleLink"></asp:Label>
        </td>
    </tr>
</table>

<script type="text/javascript">
    $(document).ready(function () {
        $('.color').colorPicker(
            {
                opacity: false, // disables opacity slider
                margin: '-29px 0px 0px 75px'
            });
        //trims any spaces included to trigger hex mode in picker
        $('.color').each(function () {
            var field = $(this).val().trim();
            $(this).val(field);
        });
    });

</script>
